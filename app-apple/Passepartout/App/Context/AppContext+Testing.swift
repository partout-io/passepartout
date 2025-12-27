// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import AppLibrary
import AppResources
import CommonLibrary
import Foundation
import Partout

extension AppContext {
    static func forUITesting() -> AppContext {
        let appConfiguration = Resources.newAppConfiguration(
            distributionTarget: .appStore,
            buildTarget: .app
        )
        let registry = appConfiguration.newRegistry(
            deviceId: "TestDeviceID",
            configBlock: { [] }
        )
        let appEncoder = AppEncoder(registry: registry)
        let ctx: PartoutLoggerContext = .global

        var logger = PartoutLogger.Builder()
        logger.setDestination(SimpleLogDestination(), for: [.App.core, .App.profiles])
        PartoutLogger.register(logger.build())
        let appLogger = PartoutAppLogger { _, msg in msg }

        let kvStore = InMemoryStore()
        let apiManager = APIManager(
            ctx,
            from: API.bundled,
            repository: InMemoryAPIRepository(ctx)
        )
        let iapManager = IAPManager(
            customUserLevel: .complete,
            inAppHelper: appConfiguration.newAppProductHelper(),
            receiptReader: FakeAppReceiptReader(),
            betaChecker: TestFlightChecker(),
            timeoutInterval: appConfiguration.constants.iap.productsTimeoutInterval,
            verificationDelayMinutesBlock: { _ in
                2
            },
            productsAtBuild: { _ in
                []
            }
        )
        let processor = appConfiguration.newAppProcessor(
            apiManager: apiManager,
            iapManager: iapManager,
            registry: registry,
            preview: \.localizedPreview,
            providerServerSorter: {
                $0.sort(using: $1.sortingComparators)
            }
        )
        let profileManager: ProfileManager = .forUITesting(
            withRegistry: registry,
            processor: processor
        )
        profileManager.isRemoteImportingEnabled = true
        let tunnel = ExtendedTunnel(
            tunnel: Tunnel(ctx, strategy: FakeTunnelStrategy()) { _ in
                SharedTunnelEnvironment(profileId: nil)
            },
            processor: processor,
            interval: appConfiguration.constants.tunnel.refreshInterval
        )
        let configManager = ConfigManager()
        let preferencesManager = PreferencesManager()
        let webReceiverManager = WebReceiverManager()
        let versionChecker = VersionChecker()

        let abi = AppABI(
            apiManager: apiManager,
            appConfiguration: appConfiguration,
            appEncoder: appEncoder,
            appLogger: appLogger,
            configManager: configManager,
            extensionInstaller: nil,
            iapManager: iapManager,
            kvStore: kvStore,
            preferencesManager: preferencesManager,
            profileManager: profileManager,
            registry: registry,
            tunnel: tunnel,
            versionChecker: versionChecker,
            webReceiverManager: webReceiverManager
        )
        return AppContext(abi: abi, appConfiguration: appConfiguration, kvStore: kvStore)
    }
}
