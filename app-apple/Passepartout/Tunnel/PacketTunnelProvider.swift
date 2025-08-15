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

        // FIXME: #1508, register global logger here

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

        let processor = DefaultTunnelProcessor()
        let neTunnelController = try await NETunnelController(
            provider: self,
            decoder: dependencies.neProtocolCoder(.global, registry: registry),
            registry: registry,
            options: {
                var options = NETunnelController.Options()
                if preferences.dnsFallsBack {
                    options.dnsFallbackServers = constants.tunnel.dnsFallbackServers
                }
                return options
            }(),
            environmentFactory: {
                dependencies.tunnelEnvironment(profileId: $0)
            },
            willProcess: processor.willProcess
        )
        let originalProfile = neTunnelController.originalProfile

        // MARK: Create PartoutLoggerContext with profile

        let ctx = PartoutLogger.register(
            for: .tunnel(originalProfile.id, distributionTarget),
            with: preferences
        )
        self.ctx = ctx
        try await trackContext(ctx)

        pp_log(ctx, .app, .info, "Tunnel started with options: \(options?.description ?? "nil")")
        if let startPreferences {
            pp_log(ctx, .app, .info, "\tDecoded preferences: \(startPreferences)")
        } else {
            pp_log(ctx, .app, .info, "\tExisting preferences: \(preferences)")
        }

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
                manager.isEnabled = !kvManager.bool(forKey: AppPreference.skipsPurchases.key)
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
            var factoryOptions = NEInterfaceFactory.Options()
            factoryOptions.usesNetworkFramework = preferences.usesNESocket || preferences.usesModernCrypto

            // OpenVPNImplementationBuilder will retrieve the
            // preferences in the connectionBlock
            var connectionOptions = ConnectionParameters.Options()
            connectionOptions.userInfo = preferences

            fwd = try NEPTPForwarder(
                ctx,
                controller: neTunnelController,
                factoryOptions: factoryOptions,
                connectionOptions: connectionOptions
            )
            guard let fwd else {
                fatalError("NEPTPForwarder nil without throwing error?")
            }

            let environment = fwd.environment

            // check hold flag
            if environment.environmentValue(forKey: TunnelEnvironmentKeys.holdFlag) == true {
                pp_log(ctx, .app, .info, "Tunnel is on hold")
                guard options?[ExtendedTunnel.isManualKey] == true as NSNumber else {
                    pp_log(ctx, .app, .error, "Tunnel was started non-interactively, hang here")
                    return
                }
                pp_log(ctx, .app, .info, "Tunnel was started interactively, clear hold flag")
                environment.removeEnvironmentValue(forKey: TunnelEnvironmentKeys.holdFlag)
            }

            // prepare for receipt verification
            await iapManager.fetchLevelIfNeeded()
            let isBeta = await iapManager.isBeta
            let params = constants.tunnel.verificationParameters(isBeta: isBeta)
            pp_log(ctx, .app, .info, "Will start profile verification in \(params.delay) seconds")

            // start tunnel
            try await fwd.startTunnel(options: [:])

            // do not run the verification loop if IAPs are not supported
            // just ensure that the profile does not require any paid feature
            if !distributionTarget.supportsIAP {
                guard originalProfile.features.isEmpty else {
                    throw PartoutError(.App.ineligibleProfile)
                }
                return
            }

            // #1070, do not wait for this to start the tunnel. if on-demand is
            // enabled, networking will stall and StoreKit network calls may
            // produce a deadlock
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
                    interval: params.interval
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
    func verifyEligibility(
        of profile: Profile,
        iapManager: IAPManager,
        environment: TunnelEnvironment,
        interval: TimeInterval
    ) async {
        guard let ctx else {
            fatalError("Forgot to set ctx?")
        }
        while true {
            guard !Task.isCancelled else {
                return
            }
            do {
                pp_log(ctx, .app, .info, "Verify profile, requires: \(profile.features)")
                await iapManager.reloadReceipt()
                try await iapManager.verify(profile)
            } catch {
                let error = PartoutError(.App.ineligibleProfile)
                environment.setEnvironmentValue(error.code, forKey: TunnelEnvironmentKeys.lastErrorCode)
                pp_log(ctx, .app, .fault, "Verification failed for profile \(profile.id), shutting down: \(error)")

                // prevent on-demand reconnection
                environment.setEnvironmentValue(true, forKey: TunnelEnvironmentKeys.holdFlag)
                await fwd?.holdTunnel()
                return
            }

            pp_log(ctx, .app, .info, "Will verify profile again in \(interval) seconds...")
            try? await Task.sleep(interval: interval)
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
