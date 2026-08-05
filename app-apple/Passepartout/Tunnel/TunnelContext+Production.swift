// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#if canImport(CommonLibraryApple)
import CommonLibrary
import NetworkExtension
import Partout
// import PartoutRuntime
import TunnelLibrary

extension TunnelContext {
    public static func forProduction(
        appConfiguration: ABI.AppConfiguration,
        preferences: AppPreferencesStore,
        startPreferences: ABI.AppPreferencesProtocol?,
        // TODO: #218, cachesURL must be per-profile
        cachesURL: URL,
        neProvider: NEPacketTunnelProvider
    ) async throws -> TunnelContext {
        let backend: TunnelBackendProtocol
        let originalProfile: Profile
        let processedProfile: Profile

        guard let bundleIdentifier = Bundle.main.bundleIdentifier else {
            fatalError("Nil .bundleIdentifier?")
        }

//        if preferences.isFlagEnabled(.zigRuntime) {
//            pspLog(.core, .info, "Using Zig runtime (\(PartoutProviderRuntime.version))")
//
//            let appGroup = appConfiguration.bundle.bundleString(for: .groupId)
//            guard let defaults = UserDefaults(suiteName: appGroup) else {
//                fatalError("No access to App Group: \(appGroup)")
//            }
//            // TODO: #218, cachesURL must be per-profile
//            let cachesURL = FileManager.default.temporaryDirectory
//            // FIXME: ###, Profile decoding requires no registry
//            let registry = appConfiguration.newRegistryForTunnel(
//                preferences: preferences,
//                cachesURL: cachesURL
//            )
//            let decoder = appConfiguration.newNEProtocolCoder(.global, coder: registry)
//            let runtime = try PartoutProviderRuntime(
//                provider: neProvider,
//                decoder: decoder,
//                options: .init(
//                    dnsFallbackServers: appConfiguration.constants.tunnel.dnsFallbackServers,
//                    logsSnapshots: false
//                ),
//                defaults: defaults,
//                logsPrivateData: preferences[\.logsPrivateData],
//                cacheDir: cachesURL.path(),
//                minDataCountDelta: appConfiguration.constants.tunnel.minDataCountDelta,
//                logger: { level, message in
//                    guard let level = ABI.AppLogLevel(partoutCLevel: level),
//                          let message else { return }
//                    pspLog(.abi, level, String(cString: message))
//                }
//            )
//            backend = runtime
//        } else {
            pspLog(.core, .info, "Using Swift runtime")

            // Create global registry
            let registry = appConfiguration.newRegistryForTunnel(
                preferences: preferences,
                cachesURL: cachesURL
            )

            // Decode profile from NE provider
            do {
                let keychain = appConfiguration.newKeychain(
                    .global,
                    bundleIdentifier: bundleIdentifier
                )
                let decoder = appConfiguration.newNEProtocolCoder(
                    .global,
                    coder: registry,
                    keychain: keychain
                )
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
            let logFormatter = appConfiguration.newLogFormatter()
            let ctx = pspLogRegister(
                for: .tunnelProfile(processedProfile.id),
                with: appConfiguration,
                preferences: preferences,
                localURL: appConfiguration.urlForTunnelLog,
                localMapper: logFormatter?.localMapper
            )

            // Decode preferences and config flags
            pspLog(ctx.profileId, .core, .info, "Tunnel profile initialized")
            if let startPreferences {
                pspLog(ctx.profileId, .core, .info, "\tDecoded preferences: \(startPreferences)")
            } else {
                pspLog(ctx.profileId, .core, .info, "\tExisting preferences: \(preferences)")
            }
            let configFlags = preferences[\.configFlags]
            pspLog(ctx.profileId, .core, .info, "\tActive config flags: \(configFlags)")
            pspLog(ctx.profileId, .core, .info, "\tIgnored config flags: \(preferences[\.experimental.ignoredConfigFlags])")
            pspLog(ctx.profileId, .core, .info, "\tEnabled config flags: \(preferences[\.experimental.enabledConfigFlags])")

            // Create TunnelController for connnection management
            let neTunnelController = NETunnelController(
                provider: neProvider,
                profile: processedProfile,
                options: {
                    var options = TunnelControllerOptions()
                    if preferences[\.dnsFallsBack] {
                        options.dnsFallbackServers = appConfiguration.constants.tunnel.dnsFallbackServers
                    }
                    return options
                }()
            )

            // Create daemon
            let factory: NetworkInterfaceFactory
            if preferences.isFlagEnabled(.ovpnV3) {
                factory = NativeSocketFactory(ctx, betterPathFactory: NEBetterPathStreamFactory(ctx))
            } else {
                let options = NEInterfaceFactory.Options()
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
                startsImmediately: true,
                cancelsUnrecoverable: false // Prevents on-demand reconnection
            )
            let daemon = try SimpleConnectionDaemon(params: params)
            backend = daemon
//        }

        // Create IAPManager for receipt verification
        let iapManager = appConfiguration.newIAPManager(
            inAppHelper: appConfiguration.newInAppHelper(),
            receiptReader: SharedReceiptReader(
                reader: appConfiguration.newInAppReceiptReader {
                    // TODO: #1786, StoreKit receipt caching
                    .uncached
                },
            ),
            betaChecker: appConfiguration.newBetaChecker()
        )
        await iapManager.fetchLevelIfNeeded()
        let skipsPurchases = !appConfiguration.bundle.distributionTarget.supportsIAP || preferences[\.skipsPurchases]
        let verificationParameters = appConfiguration.constants.tunnel.verificationParameters(isBeta: iapManager.isBeta)
        // Relax verification strategy based on AppPreference
        // Assemble
        let iap = TunnelContext.IAP(
            manager: iapManager,
            skipsPurchases: skipsPurchases,
            verificationParameters: verificationParameters,
            usesRelaxedVerification: true
        )

        return TunnelContext(
            backend: backend,
            environment: environment,
            iap: iap,
            originalProfile: originalProfile
        )
    }
}
#endif
