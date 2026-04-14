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

        // Parse preferences
        let preferences = ABI.AppPreferenceValues(
            with: decoder,
            data: preferencesData,
            newDeviceId: true
        )

        // Decode app configuration
        let bundle = try decoder.decode(ABI.AppBundle.self, from: appBundleData)
        let constants = try decoder.decode(ABI.AppConstants.self, from: appConstantsData)
        let appConfiguration = ABI.AppConfiguration(bundle: bundle, constants: constants)

        // FIXME: #1656, C ABI, get cross-platform from AppConfiguration

        // FIXME: #1656, C ABI, cross-platform log formatter and preferences
        let logFormatter = DummyLogFormatter()
        let kvStore = InMemoryStore()

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
            fetcher: { _ in
                // FIXME: #1656, C ABI, cross-platform URL requests
                Data()
            }
        )
        let registry = appConfiguration.newAppRegistry(
            configManager: configManager,
            kvStore: kvStore,
            cachesURL: cachesURL
        )

        let appEncoder = AppEncoder(coder: registry, kvStore: kvStore)
        let profileRepository = try FileProfileRepository(
            directoryURL: URL(filePath: profilesDir, directoryHint: .isDirectory)
        )
        let profileManager = ProfileManager(repository: profileRepository)
        // FIXME: #1656, C ABI, tunnel manager (real tunnel)
        let tunnel = Tunnel(ctx, strategy: FakeTunnelStrategy()) { @Sendable profileId in
            // FIXME: #1656, C ABI, IPC tunnel environment
            SharedTunnelEnvironment(profileId: profileId)
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
