// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#if canImport(CommonLibraryApple)
import NetworkExtension
import Partout

extension TunnelABI {
    public static func forNetworkExtension(
        appConfiguration: ABI.AppConfiguration,
        preferences: ABI.AppPreferenceValues,
        startPreferences: ABI.AppPreferenceValues?,
        // TODO: #218, cachesURL must be per-profile
        cachesURL: URL,
        neProvider: NEPacketTunnelProvider
    ) async throws -> TunnelABI {
        let logFormatter = appConfiguration.newLogFormatter()

        // Create global registry
        let registry = appConfiguration.newRegistryForTunnel(
            preferences: preferences,
            cachesURL: cachesURL
        )

        // Decode profile from NE provider
        let originalProfile: Profile
        let processedProfile: Profile
        do {
            let decoder = appConfiguration.newNEProtocolCoder(.global, coder: registry)
            originalProfile = try Profile(withNEProvider: neProvider, decoder: decoder)
            let resolvedProfile = try registry.resolvedProfile(originalProfile)
            let processor = appConfiguration.newTunnelProcessor()
            processedProfile = try processor.willProcess(resolvedProfile)
        } catch {
            pspLog(.profiles, .fault, "Unable to decode or process profile: \(error)")
            throw error
        }

        // Update the logger now that we have a context
        assert(processedProfile.id == originalProfile.id)
        let ctx = pspLogRegister(
            for: .tunnelProfile(processedProfile.id),
            with: appConfiguration,
            preferences: preferences,
            mapper: {
                logFormatter.formattedLog(timestamp: $0.timestamp, message: $0.message)
            }
        )

        // Decode preferences and config flags
        pspLog(ctx.profileId, .core, .info, "Tunnel profile initialized")
        if let startPreferences {
            pspLog(ctx.profileId, .core, .info, "\tDecoded preferences: \(startPreferences)")
        } else {
            pspLog(ctx.profileId, .core, .info, "\tExisting preferences: \(preferences)")
        }
        let configFlags = preferences.configFlags
        pspLog(ctx.profileId, .core, .info, "\tActive config flags: \(configFlags)")
        pspLog(ctx.profileId, .core, .info, "\tIgnored config flags: \(preferences.experimental.ignoredConfigFlags)")

        // Create TunnelController for connnection management
        let neTunnelController = NETunnelController(
            provider: neProvider,
            profile: processedProfile,
            options: {
                var options = NETunnelController.Options()
                if preferences.dnsFallsBack {
                    options.dnsFallbackServers = appConfiguration.constants.tunnel.dnsFallbackServers
                }
                return options
            }()
        )

        // Create daemon
        let factory: NetworkInterfaceFactory
        if preferences.isFlagEnabled(.bsdSockets) {
            factory = BSDSocketFactory(ctx) {
                // FIXME: #190, BetterPathBlock via NWPathMonitor
                PassthroughStream()
            }
        } else {
            // MUST enable .withReadPackets for OpenVPN V2 to work!
            var options = NEInterfaceFactory.Options()
            options.withReadPackets = preferences.isFlagEnabled(.ovpnCrossV2)
            factory = NEInterfaceFactory(ctx, provider: neProvider, options: options)
        }
        let reachability = NEObservablePath(ctx)
        let environment = appConfiguration.newTunnelEnvironment(profileId: processedProfile.id)
        let connectionOptions = ConnectionParameters.Options()
        let connectionParameters = ConnectionParameters(
            profile: processedProfile,
            controller: neTunnelController,
            factory: factory,
            reachability: reachability,
            environment: environment,
            options: connectionOptions
        )
        let messageHandler = DefaultMessageHandler(ctx, environment: environment)
        let params = SimpleConnectionDaemon.Parameters(
            connectionFactory: registry,
            connectionParameters: connectionParameters,
            messageHandler: messageHandler,
            startsImmediately: true
        )
        let daemon = try SimpleConnectionDaemon(params: params)

        // Create IAPManager for receipt verification
        let iapManager = appConfiguration.newIAPManager(
            inAppHelper: appConfiguration.newAppProductHelper(),
            receiptReader: SharedReceiptReader(
                reader: StoreKitReceiptReader(),
            ),
            betaChecker: appConfiguration.newBetaChecker()
        )
        await iapManager.fetchLevelIfNeeded()
        let skipsPurchases = !appConfiguration.bundle.distributionTarget.supportsIAP || preferences.skipsPurchases
        let verificationParameters = appConfiguration.constants.tunnel.verificationParameters(isBeta: iapManager.isBeta)
        // Relax verification strategy based on AppPreference
        let usesRelaxedVerification = preferences.relaxedVerification
        // Assemble
        let iap = TunnelABI.IAP(
            manager: iapManager,
            skipsPurchases: skipsPurchases,
            verificationParameters: verificationParameters,
            usesRelaxedVerification: usesRelaxedVerification
        )

        return TunnelABI(
            daemon: daemon,
            environment: environment,
            iap: iap,
            logFormatter: logFormatter,
            originalProfile: originalProfile
        )
    }
}
#endif
