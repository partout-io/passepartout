// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonLibrary
import CommonUtils
@preconcurrency import NetworkExtension

final class PacketTunnelProvider: NEPacketTunnelProvider, @unchecked Sendable {
    private var ctx: PartoutLoggerContext?

    private var fwd: NEPTPForwarder?

    private var verifierSubscription: Task<Void, Error>?

    override func startTunnel(options: [String: NSObject]? = nil) async throws {

        // FIXME: #1508, register global logger ASAP (logs before registration are lost)

        let startPreferences: AppPreferenceValues?
        if let encodedPreferences = options?[ExtendedTunnel.appPreferences] as? NSData {
            do {
                startPreferences = try JSONDecoder()
                    .decode(AppPreferenceValues.self, from: encodedPreferences as Data)
            } catch {
                pp_log_g(.app, .error, "Unable to decode startTunnel() preferences")
                startPreferences = nil
            }
        } else {
            startPreferences = nil
        }

        // MARK: Declare globals

        let dependencies: Dependencies = await .shared
        let distributionTarget = Dependencies.distributionTarget
        let constants: Constants = .shared

        // MARK: Update or fetch existing preferences

        let (kvManager, preferences) = await MainActor.run {
            let kvManager = dependencies.kvManager
            if let startPreferences {
                kvManager.preferences = startPreferences
                return (kvManager, startPreferences)
            } else {
                return (kvManager, kvManager.preferences)
            }
        }

        // MARK: Registry

        assert(preferences.deviceId != nil, "No Device ID found in preferences")
        let registry = dependencies.newRegistry(
            distributionTarget: distributionTarget,
            deviceId: preferences.deviceId ?? "MissingDeviceID"
        )
        pp_log_g(.app, .info, "Device ID: \(preferences.deviceId ?? "not set")")
        CommonLibrary.assertMissingImplementations(with: registry)

        // MARK: Parse profile

        // Decode profile from NE provider
        let decoder = dependencies.neProtocolCoder(.global, registry: registry)
        let originalProfile: Profile
        do {
            originalProfile = try Profile(withNEProvider: self, decoder: decoder)
        } catch {
            pp_log_g(.App.profiles, .fault, "Unable to decode profile: \(error)")
            flushLogs()
            throw error
        }

        // Create PartoutLoggerContext with profile
        let ctx = PartoutLogger.register(
            for: .tunnel(originalProfile.id, distributionTarget),
            with: preferences
        )
        self.ctx = ctx
        try await trackContext(ctx)

        // Post-process profile (e.g. resolve and apply local preferences)
        let resolvedProfile: Profile
        let processedProfile: Profile
        do {
            resolvedProfile = try registry.resolvedProfile(originalProfile)
            let processor = DefaultTunnelProcessor()
            processedProfile = try processor.willProcess(resolvedProfile)
            assert(processedProfile.id == originalProfile.id)
        } catch {
            pp_log(ctx, .App.profiles, .fault, "Unable to process profile: \(error)")
            flushLogs()
            throw error
        }

        // MARK: Create TunnelController for connnection management

        let neTunnelController: NETunnelController
        do {
            neTunnelController = try await NETunnelController(
                provider: self,
                profile: processedProfile,
                options: {
                    var options = NETunnelController.Options()
                    if preferences.dnsFallsBack {
                        options.dnsFallbackServers = constants.tunnel.dnsFallbackServers
                    }
                    return options
                }()
            )
        } catch {
            pp_log(ctx, .app, .fault, "Unable to create NETunnelController: \(error)")
            flushLogs()
            throw error
        }

        pp_log(ctx, .app, .info, "Tunnel started with options: \(options?.description ?? "nil")")
        if let startPreferences {
            pp_log(ctx, .app, .info, "\tDecoded preferences: \(startPreferences)")
        } else {
            pp_log(ctx, .app, .info, "\tExisting preferences: \(preferences)")
        }
        let configFlags = preferences.configFlags
        pp_log(ctx, .app, .info, "\tActive config flags: \(configFlags)")

        // MARK: Create IAPManager for verification

        let iapManager = await MainActor.run {
            let manager = IAPManager(
                customUserLevel: dependencies.customUserLevel,
                inAppHelper: dependencies.appProductHelper(),
                receiptReader: SharedReceiptReader(
                    reader: StoreKitReceiptReader(logger: dependencies.iapLogger()),
                ),
                betaChecker: dependencies.betaChecker(),
                productsAtBuild: dependencies.productsAtBuild()
            )
            if distributionTarget.supportsIAP {
                manager.isEnabled = !kvManager.bool(forAppPreference: .skipsPurchases)
            } else {
                manager.isEnabled = false
            }
            return manager
        }

        // MARK: Start with NEPTPForwarder

        guard self.ctx != nil else {
            fatalError("Do not forget to save ctx locally")
        }
        do {
            // Environment for app/tunnel IPC
            let environment = dependencies.tunnelEnvironment(profileId: processedProfile.id)

            // Pick socket and crypto strategy from preferences
            var factoryOptions = NEInterfaceFactory.Options()
            factoryOptions.usesNetworkFramework = configFlags.contains(.neSocket) || preferences.usesModernCrypto

            // OpenVPNImplementationBuilder will retrieve the
            // preferences in the connectionBlock
            var connectionOptions = ConnectionParameters.Options()
            connectionOptions.userInfo = preferences

            fwd = try NEPTPForwarder(
                ctx,
                profile: processedProfile,
                registry: registry,
                controller: neTunnelController,
                environment: environment,
                factoryOptions: factoryOptions,
                connectionOptions: connectionOptions
            )
            guard let fwd else {
                fatalError("NEPTPForwarder nil without throwing error?")
            }

            // Check hold flag and hang the tunnel if set
            if environment.environmentValue(forKey: TunnelEnvironmentKeys.holdFlag) == true {
                pp_log(ctx, .app, .info, "Tunnel is on hold")
                guard options?[ExtendedTunnel.isManualKey] == true as NSNumber else {
                    pp_log(ctx, .app, .error, "Tunnel was started non-interactively, hang here")
                    return
                }
                pp_log(ctx, .app, .info, "Tunnel was started interactively, clear hold flag")
                environment.removeEnvironmentValue(forKey: TunnelEnvironmentKeys.holdFlag)
            }

            // Prepare for receipt verification
            await iapManager.fetchLevelIfNeeded()
            let isBeta = await iapManager.isBeta
            let params = constants.tunnel.verificationParameters(isBeta: isBeta)
            pp_log(ctx, .App.iap, .info, "Will start profile verification in \(params.delay) seconds")

            // Start the tunnel (ignore all start options)
            try await fwd.startTunnel(options: [:])

            // Do not run the verification loop if IAPs are not supported
            // just ensure that the profile does not require any paid feature
            if !distributionTarget.supportsIAP {
                guard originalProfile.features.isEmpty else {
                    throw PartoutError(.App.ineligibleProfile)
                }
                return
            }

            // Relax verification strategy based on AppPreference
            let isRelaxedVerification = await kvManager.bool(forAppPreference: .relaxedVerification)

            // Do not wait for this to start the tunnel. If on-demand is
            // enabled, networking will stall and StoreKit network calls may
            // produce a deadlock (see #1070)
            verifierSubscription = Task { [weak self] in
                guard let self else {
                    return
                }
                try await Task.sleep(for: .seconds(params.delay))
                guard !Task.isCancelled else {
                    return
                }
                await verifyEligibility(
                    of: originalProfile,
                    iapManager: iapManager,
                    environment: environment,
                    params: params,
                    isRelaxed: isRelaxedVerification
                )
            }
        } catch {
            pp_log(ctx, .app, .fault, "Unable to start tunnel: \(error)")
            flushLogs()
            throw error
        }
    }

    override func stopTunnel(with reason: NEProviderStopReason) async {
        verifierSubscription?.cancel()
        await fwd?.stopTunnel(with: reason)
        fwd = nil
        flushLogs()
        await untrackContext()
        ctx = nil
    }

    override func cancelTunnelWithError(_ error: (any Error)?) {
        flushLogs()
        super.cancelTunnelWithError(error)
    }

    override func handleAppMessage(_ messageData: Data) async -> Data? {
        await fwd?.handleAppMessage(messageData)
    }

    override func wake() {
        fwd?.wake()
    }

    override func sleep() async {
        await fwd?.sleep()
    }
}

private extension PacketTunnelProvider {
    func flushLogs() {
        PartoutLogger.default.flushLog()
    }
}

// MARK: - Tracking

@MainActor
private extension PacketTunnelProvider {
    static var activeTunnels: Set<Profile.ID> = [] {
        didSet {
            pp_log_g(.app, .info, "Active tunnels: \(activeTunnels)")
        }
    }

    func trackContext(_ ctx: PartoutLoggerContext) throws {
        guard let profileId = ctx.profileId else {
            return
        }
        // TODO: #218, keep this until supported
        guard Self.activeTunnels.isEmpty else {
            throw PartoutError(.App.multipleTunnels)
        }
        pp_log_g(.app, .info, "Track context: \(profileId)")
        Self.activeTunnels.insert(profileId)
    }

    func untrackContext() {
        guard let profileId = ctx?.profileId else {
            return
        }
        pp_log_g(.app, .info, "Untrack context: \(profileId)")
        Self.activeTunnels.remove(profileId)
    }
}

// MARK: - Eligibility

private extension PacketTunnelProvider {

    @MainActor
    func verifyEligibility(
        of profile: Profile,
        iapManager: IAPManager,
        environment: TunnelEnvironment,
        params: Constants.Tunnel.Verification.Parameters,
        isRelaxed: Bool
    ) async {
        guard let ctx else {
            fatalError("Forgot to set ctx?")
        }
        var attempts = params.attempts
        while true {
            guard !Task.isCancelled else {
                return
            }
            do {
                pp_log(ctx, .App.iap, .info, "Verify profile, requires: \(profile.features)")
                await iapManager.reloadReceipt()
                try iapManager.verify(profile)
            } catch {
                if isRelaxed {
                    // Mitigate the StoreKit inability to report errors, sometimes it
                    // would just return empty products, e.g. on network failure. In those
                    // cases, retry a few times before failing
                    if attempts > 0 {
                        attempts -= 1
                        pp_log(ctx, .App.iap, .error, "Verification failed for profile \(profile.id), next attempt in \(params.retryInterval) seconds... (remaining: \(attempts), products: \(iapManager.purchasedProducts))")
                        try? await Task.sleep(interval: params.retryInterval)
                        continue
                    }
                }

                let error = PartoutError(.App.ineligibleProfile)
                environment.setEnvironmentValue(error.code, forKey: TunnelEnvironmentKeys.lastErrorCode)
                pp_log(ctx, .App.iap, .fault, "Verification failed for profile \(profile.id), shutting down: \(error)")

                // Hold on failure to prevent on-demand reconnection
                environment.setEnvironmentValue(true, forKey: TunnelEnvironmentKeys.holdFlag)
                await fwd?.holdTunnel()
                return
            }

            pp_log(ctx, .App.iap, .info, "Will verify profile again in \(params.interval) seconds...")
            try? await Task.sleep(interval: params.interval)

            // On successful verification, reset attempts for the next verification
            attempts = params.attempts
        }
    }
}

private extension TunnelEnvironmentKeys {
    static let holdFlag = TunnelEnvironmentKey<Bool>("Tunnel.onHold")
}

extension PartoutError: @retroactive LocalizedError {
    public var errorDescription: String? {
        debugDescription
    }
}
