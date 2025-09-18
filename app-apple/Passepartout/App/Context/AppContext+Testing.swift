// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import AppLibrary
import CommonLibrary
import CommonUtils
import Foundation

extension AppContext {
    static var forUITesting: AppContext {
        let dependencies: Dependencies = .shared
        let constants: Constants = .shared
        let ctx: PartoutLoggerContext = .global

        var logger = PartoutLogger.Builder()
        logger.setDestination(NSLogDestination(), for: [.app, .App.profiles])
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
            interval: constants.tunnel.refreshInterval
        )
        let configManager = ConfigManager()
        let migrationManager = MigrationManager()
        let preferencesManager = PreferencesManager()
        let webReceiverManager = WebReceiverManager()

        return AppContext(
            apiManager: apiManager,
            configManager: configManager,
            distributionTarget: Dependencies.distributionTarget,
            iapManager: iapManager,
            kvManager: kvManager,
            migrationManager: migrationManager,
            preferencesManager: preferencesManager,
            profileCoder: dependencies.sharedProfileCoder,
            profileManager: profileManager,
            registry: registry,
            sysexManager: nil,
            tunnel: tunnel,
            webReceiverManager: webReceiverManager
        )
    }
}
