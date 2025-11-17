// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import AppLibrary
import CommonLibrary
import CommonResources
import Foundation
import Partout

extension AppContext {
    static var forUITesting: AppContext {
        let dependencies: Dependencies = .shared
        let appConfiguration = Resources.newAppConfiguration(
            distributionTarget: Dependencies.distributionTarget,
            buildTarget: .app
        )
        let ctx: PartoutLoggerContext = .global

        var logger = PartoutLogger.Builder()
        logger.setDestination(NSLogDestination(), for: [.App.core, .App.profiles])
        PartoutLogger.register(logger.build())

        let kvManager = KeyValueManager()
        let apiManager = APIManager(
            ctx,
            from: API.bundled,
            repository: InMemoryAPIRepository(ctx)
        )
        let iapManager = IAPManager(
            customUserLevel: .complete,
            inAppHelper: dependencies.appProductHelper(cfg: appConfiguration),
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
        let registry = dependencies.newRegistry(
            distributionTarget: .appStore,
            deviceId: "TestDeviceID",
            configBlock: { [] }
        )
        let processor = dependencies.appProcessor(
            cfg: appConfiguration,
            apiManager: apiManager,
            iapManager: iapManager,
            registry: registry
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

        return AppContext(
            apiManager: apiManager,
            appConfiguration: appConfiguration,
            appEncoder: AppEncoder(registry: registry),
            configManager: configManager,
            iapManager: iapManager,
            kvManager: kvManager,
            logger: PartoutLoggerStrategy(),
            preferencesManager: preferencesManager,
            profileManager: profileManager,
            registry: registry,
            sysexManager: nil,
            tunnel: tunnel,
            versionChecker: versionChecker,
            webReceiverManager: webReceiverManager
        )
    }
}
