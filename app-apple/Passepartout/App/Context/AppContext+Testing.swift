// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import AppLibrary
import CommonLibrary
import Foundation
import Partout

extension AppContext {
    static func forUITesting() -> AppContext {
        let dependencies = Dependencies(buildTarget: .app)
        let appConfiguration = dependencies.appConfiguration
        let appLogger = dependencies.appLogger()
        let registry = dependencies.newRegistry(
            deviceId: "TestDeviceID",
            configBlock: { [] }
        )
        let appEncoder = AppEncoder(registry: registry)
        let ctx: PartoutLoggerContext = .global

        var logger = PartoutLogger.Builder()
        logger.setDestination(SimpleLogDestination(), for: [.App.core, .App.profiles])
        PartoutLogger.register(logger.build())

        let kvManager = KeyValueManager()
        let apiManager = APIManager(
            ctx,
            from: API.bundled,
            repository: InMemoryAPIRepository(ctx)
        )
        let iapManager = IAPManager(
            customUserLevel: .complete,
            inAppHelper: dependencies.appProductHelper(),
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
        let processor = dependencies.appProcessor(
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
            appEncoder: appEncoder,
            configManager: configManager,
            iapManager: iapManager,
            kvManager: kvManager,
            logger: appLogger,
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
