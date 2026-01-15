// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import AppResources
import CommonLibrary
@preconcurrency import NetworkExtension
// FIXME: #1594, Drop import
import Partout

final class PacketTunnelProvider: NEPacketTunnelProvider, @unchecked Sendable {
    private var abi: TunnelABIProtocol?

    // FIXME: #1594, Deprecated state in favor of ABI (config flag)
    @available(*, deprecated, message: "#1594")
    private var ctx: PartoutLoggerContext?
    @available(*, deprecated, message: "#1594")
    private var fwd: NEPTPForwarder?
    @available(*, deprecated, message: "#1594")
    private var verifierSubscription: Task<Void, Error>?

    override func startTunnel(options: [String: NSObject]? = nil, completionHandler: @escaping @Sendable (Error?) -> Void) {
        let distributionTarget: ABI.DistributionTarget
#if PP_BUILD_MAC
        distributionTarget = .developerID
#else
        distributionTarget = .appStore
#endif
        let appConfiguration = Resources.newAppConfiguration(
            distributionTarget: distributionTarget,
            buildTarget: .tunnel
        )
        let logFormatter = appConfiguration.newLogFormatter()

        // Register essential logger ASAP because the profile context
        // can only be defined after decoding the profile. We would
        // in fact miss profile decoding errors. Re-register the
        // profile-aware context later.
        _ = pspLogRegister(
            for: .tunnelGlobal,
            with: appConfiguration,
            preferences: ABI.AppPreferenceValues(),
            mapper: { [weak logFormatter] in
                logFormatter?.formattedLog(timestamp: $0.timestamp, message: $0.message) ?? $0.message
            }
        )

        // The app may propagate its local preferences on manual start
        let isInteractive = options?[TunnelManager.isManualKey] == true as NSNumber
        let startPreferences: ABI.AppPreferenceValues? = {
            guard let encodedPreferences = options?[TunnelManager.appPreferences] as? Data else {
                return nil
            }
            do {
                return try JSONDecoder()
                    .decode(ABI.AppPreferenceValues.self, from: encodedPreferences)
            } catch {
                pspLog(.core, .error, "Unable to decode startTunnel() preferences")
                return nil
            }
        }()

        // Update or fetch existing preferences
        let (kvStore, preferences) = {
            let kvStore = appConfiguration.newKeyValueStore()
            if let startPreferences {
                kvStore.preferences = startPreferences
                return (kvStore, startPreferences)
            } else {
                return (kvStore, kvStore.preferences)
            }
        }()

        // Branch over ABI or deprecated code
        let usesTunnelABI = preferences.enabledFlags().contains(.tunnelABI)
        pp_log_g(.core, .notice, "Using Tunnel ABI: \(usesTunnelABI)")

        // Defer to ABI
        Task { @MainActor in
            do {
                if usesTunnelABI {
                    abi = try await TunnelABI.forProduction(
                        appConfiguration: appConfiguration,
                        preferences: preferences,
                        startPreferences: startPreferences,
                        neProvider: self
                    )
                    abi?.log(.core, .notice, "Start PTP")
                    try await abi?.start(isInteractive: isInteractive)
                } else {
                    abi = nil
                    try await compatibleStartTunnel(
                        appConfiguration: appConfiguration,
                        kvStore: kvStore,
                        preferences: preferences,
                        startPreferences: startPreferences,
                        isInteractive: isInteractive
                    )
                }
                completionHandler(nil)
            } catch {
                completionHandler(error)
            }
        }
    }

    override func stopTunnel(with reason: NEProviderStopReason) async {
        if let abi {
            pspLog(.core, .notice, "Stop PTP, reason: \(String(describing: reason))")
            await abi.stop()
        } else {
            verifierSubscription?.cancel()
            await fwd?.stopTunnel(with: reason)
            fwd = nil
            flushLogs()
            await untrackContext()
        }
    }

    override func cancelTunnelWithError(_ error: Error?) {
        if let abi {
            pspLog(.core, .info, "Cancel PTP, error: \(String(describing: error))")
            abi.cancel(error)
        } else {
            flushLogs()
        }
        super.cancelTunnelWithError(error)
    }

    override func handleAppMessage(_ messageData: Data) async -> Data? {
        if let abi {
            pspLog(.core, .debug, "Handle PTP message")
            return await abi.sendMessage(messageData)
        } else {
            return await fwd?.handleAppMessage(messageData)
        }
    }

//    override func wake() {
//        fwd?.wake()
//    }
//
//    override func sleep() async {
//        await fwd?.sleep()
//    }
}

// MARK: - Deprecated code (#1594)

@available(*, deprecated, message: "Use TunnelABI")
private extension PacketTunnelProvider {
    func compatibleStartTunnel(
        appConfiguration: ABI.AppConfiguration,
        kvStore: KeyValueStore,
        preferences: ABI.AppPreferenceValues,
        startPreferences: ABI.AppPreferenceValues?,
        isInteractive: Bool
    ) async throws {
        let logFormatter = appConfiguration.newLogFormatter()

        // Create global registry
        let registry = appConfiguration.newTunnelRegistry(
            preferences: preferences
        )

        // Decode profile from NE provider
        let decoder = appConfiguration.newNEProtocolCoder(.global, registry: registry)
        let originalProfile: Profile
        do {
            originalProfile = try Profile(withNEProvider: self, decoder: decoder)
        } catch {
            pspLog(.profiles, .fault, "Unable to decode profile: \(error)")
            flushLogs()
            throw error
        }

        // Update the logger now that we have a context
        let ctx = pspLogRegister(
            for: .tunnelProfile(originalProfile.id),
            with: appConfiguration,
            preferences: preferences,
            mapper: { [weak logFormatter] in
                logFormatter?.formattedLog(timestamp: $0.timestamp, message: $0.message) ?? $0.message
            }
        )
        self.ctx = ctx
        try await trackContext(ctx)

        // Post-process profile (e.g. resolve and apply local preferences)
        let resolvedProfile: Profile
        let processedProfile: Profile
        do {
            resolvedProfile = try registry.resolvedProfile(originalProfile)
            let processor = appConfiguration.newTunnelProcessor()
            processedProfile = try processor.willProcess(resolvedProfile)
            assert(processedProfile.id == originalProfile.id)
        } catch {
            pspLog(ctx.profileId, .profiles, .fault, "Unable to process profile: \(error)")
            flushLogs()
            throw error
        }

        // Create TunnelController for connnection management
        let neTunnelController = NETunnelController(
            provider: self,
            profile: processedProfile,
            options: {
                var options = NETunnelController.Options()
                if preferences.dnsFallsBack {
                    options.dnsFallbackServers = appConfiguration.constants.tunnel.dnsFallbackServers
                }
                return options
            }()
        )

        pspLog(ctx.profileId, .core, .info, "Tunnel started")
        if let startPreferences {
            pspLog(ctx.profileId, .core, .info, "\tDecoded preferences: \(startPreferences)")
        } else {
            pspLog(ctx.profileId, .core, .info, "\tExisting preferences: \(preferences)")
        }
        let configFlags = preferences.configFlags
        pspLog(ctx.profileId, .core, .info, "\tActive config flags: \(configFlags)")
        pspLog(ctx.profileId, .core, .info, "\tIgnored config flags: \(preferences.experimental.ignoredConfigFlags)")

        // Create IAPManager for receipt verification
        let iapManager = await MainActor.run {
            let manager = IAPManager(
                customUserLevel: appConfiguration.customUserLevel,
                inAppHelper: appConfiguration.newAppProductHelper(),
                receiptReader: SharedReceiptReader(
                    reader: StoreKitReceiptReader(),
                ),
                betaChecker: appConfiguration.newBetaChecker(),
                timeoutInterval: appConfiguration.constants.iap.productsTimeoutInterval,
                verificationDelayMinutesBlock: {
                    appConfiguration.constants.tunnel.verificationDelayMinutes(isBeta: $0)
                },
                productsAtBuild: appConfiguration.newProductsAtBuild
            )
            if appConfiguration.distributionTarget.supportsIAP {
                manager.isEnabled = !preferences.skipsPurchases
            } else {
                manager.isEnabled = false
            }
            return manager
        }

        // Start with NEPTPForwarder
        guard self.ctx != nil else {
            fatalError("Do not forget to save ctx locally")
        }
        do {
            // Environment for app/tunnel IPC
            let environment = appConfiguration.newTunnelEnvironment(profileId: processedProfile.id)

            // Pick socket and crypto strategy from preferences
            var factoryOptions = NEInterfaceFactory.Options()
            factoryOptions.usesNEUDP = preferences.isFlagEnabled(.neSocketUDP)
            factoryOptions.usesNETCP = preferences.isFlagEnabled(.neSocketTCP)

            fwd = try NEPTPForwarder(
                ctx,
                profile: processedProfile,
                registry: registry,
                controller: neTunnelController,
                environment: environment,
                factoryOptions: factoryOptions
            )
            guard let fwd else {
                fatalError("NEPTPForwarder nil without throwing error?")
            }

            // Check hold flag and hang the tunnel if set
            if environment.environmentValue(forKey: TunnelEnvironmentKeys.holdFlag) == true {
                pspLog(ctx.profileId, .core, .info, "Tunnel is on hold")
                guard isInteractive else {
                    pspLog(ctx.profileId, .core, .error, "Tunnel was started non-interactively, hang here")
                    return
                }
                pspLog(ctx.profileId, .core, .info, "Tunnel was started interactively, clear hold flag")
                environment.removeEnvironmentValue(forKey: TunnelEnvironmentKeys.holdFlag)
            }

            // Prepare for receipt verification
            await iapManager.fetchLevelIfNeeded()
            let isBeta = await iapManager.isBeta
            let params = appConfiguration.constants.tunnel.verificationParameters(isBeta: isBeta)
            pspLog(ctx.profileId, .iap, .info, "Will start profile verification in \(params.delay) seconds")

            // Start the tunnel (ignore all start options)
            try await fwd.startTunnel(options: [:])

            // Do not run the verification loop if IAPs are not supported
            // just ensure that the profile does not require any paid feature
            if !appConfiguration.distributionTarget.supportsIAP {
                guard originalProfile.features.isEmpty else {
                    throw PartoutError(.App.ineligibleProfile)
                }
                return
            }

            // Relax verification strategy based on AppPreference
            let isRelaxedVerification = preferences.relaxedVerification

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
            pspLog(ctx.profileId, .core, .fault, "Unable to start tunnel: \(error)")
            flushLogs()
            throw error
        }
    }
}

private extension PacketTunnelProvider {
    func flushLogs() {
        PartoutLogger.default.flushLog()
    }
}

@MainActor
private extension PacketTunnelProvider {
    static var activeTunnels: Set<Profile.ID> = [] {
        didSet {
            pspLog(.core, .info, "Active tunnels: \(activeTunnels)")
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
        pspLog(.core, .info, "Track context: \(profileId)")
        Self.activeTunnels.insert(profileId)
    }

    func untrackContext() {
        guard let profileId = ctx?.profileId else {
            return
        }
        pspLog(.core, .info, "Untrack context: \(profileId)")
        Self.activeTunnels.remove(profileId)
    }
}

private extension PacketTunnelProvider {

    @MainActor
    func verifyEligibility(
        of profile: Profile,
        iapManager: IAPManager,
        environment: TunnelEnvironment,
        params: ABI.Constants.Tunnel.Verification.Parameters,
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
                pspLog(ctx.profileId, .iap, .info, "Verify profile, requires: \(profile.features)")
                await iapManager.reloadReceipt()
                try iapManager.legacyVerify(profile)
            } catch {
                if isRelaxed {
                    // Mitigate the StoreKit inability to report errors, sometimes it
                    // would just return empty products, e.g. on network failure. In those
                    // cases, retry a few times before failing
                    if attempts > 0 {
                        attempts -= 1
                        pspLog(ctx.profileId, .iap, .error, "Verification failed for profile \(profile.id), next attempt in \(params.retryInterval) seconds... (remaining: \(attempts), products: \(iapManager.purchasedProducts))")
                        try? await Task.sleep(interval: params.retryInterval)
                        continue
                    }
                }

                let error = PartoutError(.App.ineligibleProfile)
                environment.setEnvironmentValue(error.code, forKey: TunnelEnvironmentKeys.lastErrorCode)
                pspLog(ctx.profileId, .iap, .fault, "Verification failed for profile \(profile.id), shutting down: \(error)")

                // Hold on failure to prevent on-demand reconnection
                environment.setEnvironmentValue(true, forKey: TunnelEnvironmentKeys.holdFlag)
                await fwd?.holdTunnel()
                return
            }

            pspLog(ctx.profileId, .iap, .info, "Will verify profile again in \(params.interval) seconds...")
            try? await Task.sleep(interval: params.interval)

            // On successful verification, reset attempts for the next verification
            attempts = params.attempts
        }
    }
}

private extension TunnelEnvironmentKeys {
    static let holdFlag = TunnelEnvironmentKey<Bool>("Tunnel.onHold")
}
