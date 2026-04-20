// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#if PSP_ABI
import CommonLibrary_C
import Partout

extension AppABI {
    public static func forCrossPlatform(
        appBundleData: Data,
        appConstantsData: Data,
        preferencesData: Data?,
        profilesDir: String,
        cachesURL: URL
    ) throws -> AppABI {
        let decoder = JSONDecoder()

        // Decode app configuration
        let bundle = try decoder.decode(ABI.AppBundle.self, from: appBundleData)
        let constants = try decoder.decode(ABI.AppConstants.self, from: appConstantsData)
        let appConfiguration = ABI.AppConfiguration(bundle: bundle, constants: constants)

        // Parse preferences
        let preferences = ABI.AppPreferenceValues(
            with: decoder,
            data: preferencesData,
            newDeviceId: true,
            deviceIdLength: constants.deviceIdLength
        )

        let logFormatter = appConfiguration.newLogFormatter()
        let kvStore = appConfiguration.newKeyValueStore()
        kvStore.preferences = preferences

        // Logging context
        let ctx = pspLogRegister(
            for: .app,
            with: appConfiguration,
            preferences: preferences,
            mapper: {
                logFormatter.formattedLog(timestamp: $0.timestamp, message: $0.message)
            }
        )

        // Initialize objects from global configuration
        let configManager = appConfiguration.newConfigManager(
            withTestBundle: false,
            isBeta: {
                false
            },
            fetcher: {
                try await appConfiguration.newRequest(for: $0, cached: false)
            }
        )
        let registry = appConfiguration.newRegistryForApp(
            configManager: configManager,
            kvStore: kvStore,
            cachesURL: cachesURL
        )

        let appEncoder = AppEncoder(coder: registry, kvStore: kvStore)
        let profileRepository = try appConfiguration.newFileProfileRepository(path: profilesDir)
        let profileManager = ProfileManager(repository: profileRepository)
        let tunnelStrategy = appConfiguration.newStandaloneTunnelStrategy()
        let tunnel = Tunnel(ctx, strategy: tunnelStrategy) { @Sendable in
            appConfiguration.newAppTunnelEnvironment(strategy: tunnelStrategy, profileId: $0)
        }
        let tunnelManager = TunnelManager(tunnel: tunnel, interval: 1.0)

        // Dummy
        let iapManager = IAPManager()
        let versionChecker = VersionChecker()
        let webReceiverManager = WebReceiverManager()

        return AppABI(
            apiManager: nil,
            appConfiguration: appConfiguration,
            appEncoder: appEncoder,
            configManager: configManager,
            extensionInstaller: nil,
            iapManager: iapManager,
            kvStore: kvStore,
            logFormatter: logFormatter,
            preferencesManager: nil,
            profileManager: profileManager,
            registry: registry,
            tunnelManager: tunnelManager,
            versionChecker: versionChecker,
            webReceiverManager: webReceiverManager
        )
    }
}
#endif
