// SPDX-FileCopyrightText: 2026 Davide De Rosa
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
        let appLogger = appConfiguration.newAppLogger()
        let logFormatter = DummyLogFormatter()

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
        let profileProcessor = appConfiguration.newAppProfileProcessor(
            iapManager: iapManager,
            preview: \.localizedPreview
        )
        let profileManager: ProfileManager = .forUITesting(
            withRegistry: registry,
            processor: profileProcessor
        )
        profileManager.isRemoteImportingEnabled = true
        let tunnel = Tunnel(ctx, strategy: FakeTunnelStrategy()) { _ in
            SharedTunnelEnvironment(profileId: nil)
        }
        let tunnelProcessor = appConfiguration.newAppTunnelProcessor(
            apiManager: apiManager,
            registry: registry,
            providerServerSorter: {
                $0.sort(using: $1.sortingComparators)
            }
        )
        let tunnelManager = TunnelManager(
            tunnel: tunnel,
            processor: tunnelProcessor,
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
            logFormatter: logFormatter,
            preferencesManager: preferencesManager,
            profileManager: profileManager,
            registry: registry,
            tunnelManager: tunnelManager,
            versionChecker: versionChecker,
            webReceiverManager: webReceiverManager
        )
        return AppContext(abi: abi, appConfiguration: appConfiguration, kvStore: kvStore)
    }
}
