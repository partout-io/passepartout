// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#if canImport(CommonLibraryApple)
import NetworkExtension

extension TunnelABI {
    public static func forProduction(
        appConfiguration: ABI.AppConfiguration,
        kvStore: KeyValueStore,
        preferences: ABI.AppPreferenceValues,
        startPreferences: ABI.AppPreferenceValues?,
        neProvider: NEPacketTunnelProvider
    ) async throws -> TunnelABI {
        let logFormatter = appConfiguration.newLogFormatter()
        var appLogger = appConfiguration.newAppLogger()

        // Create global registry
        let registry = appConfiguration.newTunnelRegistry(
            appLogger: appLogger,
            preferences: preferences
        )

        // Decode profile from NE provider
        let originalProfile: Profile
        let processedProfile: Profile
        do {
            let decoder = appConfiguration.newNEProtocolCoder(.global, registry: registry)
            originalProfile = try Profile(withNEProvider: neProvider, decoder: decoder)
            let resolvedProfile = try registry.resolvedProfile(originalProfile)
            let processor = appConfiguration.newTunnelProcessor()
            processedProfile = try processor.willProcess(resolvedProfile)
        } catch {
            appLogger.log(.profiles, .fault, "Unable to decode or process profile: \(error)")
            throw error
        }

        // Update the logger now that we have a context
        assert(processedProfile.id == originalProfile.id)
        let ctx = PartoutLogger.register(
            for: .tunnelProfile(processedProfile.id),
            with: appConfiguration,
            preferences: preferences,
            mapper: { [weak logFormatter] in
                logFormatter?.formattedLog(timestamp: $0.timestamp, message: $0.message) ?? $0.message
            }
        )
        appLogger = appConfiguration.newAppLogger(profileId: processedProfile.id)

        // Decode preferences and config flags
        appLogger.log(.core, .info, "Tunnel profile initialized")
        if let startPreferences {
            appLogger.log(.core, .info, "\tDecoded preferences: \(startPreferences)")
        } else {
            appLogger.log(.core, .info, "\tExisting preferences: \(preferences)")
        }
        let configFlags = preferences.configFlags
        appLogger.log(.core, .info, "\tActive config flags: \(configFlags)")
        appLogger.log(.core, .info, "\tIgnored config flags: \(preferences.experimental.ignoredConfigFlags)")

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

        // Pick socket and crypto strategy from preferences
        var factoryOptions = NEInterfaceFactory.Options()
        factoryOptions.usesNEUDP = preferences.isFlagEnabled(.neSocketUDP)
        factoryOptions.usesNETCP = preferences.isFlagEnabled(.neSocketTCP)

        // Create daemon
        let factory = NEInterfaceFactory(ctx, provider: neProvider, options: factoryOptions)
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
            registry: registry,
            connectionParameters: connectionParameters,
            reachability: reachability,
            messageHandler: messageHandler
        )
        let daemon = try SimpleConnectionDaemon(params: params)

        // Create IAPManager for receipt verification
        let iapManager = appConfiguration.newIAPManager(
            inAppHelper: appConfiguration.newAppProductHelper(),
            receiptReader: SharedReceiptReader(
                reader: StoreKitReceiptReader(logger: appLogger),
            ),
            betaChecker: appConfiguration.newBetaChecker(),
            isEnabled: !kvStore.bool(forAppPreference: .skipsPurchases)
        )
        // Adjust verification parameters if beta
        await iapManager.fetchLevelIfNeeded()
        let verificationParameters = appConfiguration.constants.tunnel.verificationParameters(isBeta: iapManager.isBeta)
        // Relax verification strategy based on AppPreference
        let usesRelaxedVerification = kvStore.bool(forAppPreference: .relaxedVerification)
        // Assemble
        let iap = TunnelABI.IAP(
            manager: iapManager,
            verificationParameters: verificationParameters,
            usesRelaxedVerification: usesRelaxedVerification
        )

        return TunnelABI(
            appLogger: appLogger,
            daemon: daemon,
            environment: environment,
            iap: iap,
            logFormatter: logFormatter,
            originalProfile: ABI.AppProfile(native: originalProfile)
        )
    }
}
#endif
