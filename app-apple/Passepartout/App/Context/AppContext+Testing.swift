// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import AppLibrary
import AppResources
import CommonLibrary

extension AppContext {
    static func forUITesting() -> AppContext {
        let appConfiguration = Resources.newAppConfiguration(
            distributionTarget: .appStore,
            buildTarget: .app
        )
        let registry = appConfiguration.makeRegistry(
            deviceId: "TestDeviceID",
            cachesURL: FileManager.default.temporaryDirectory,
            configBlock: { [] }
        )
        let preferences = AppPreferencesStore()
        let defaults = UserDefaults()
        let appEncoder = AppEncoder(coder: registry)

        pspLogRegister(
            for: .app,
            with: appConfiguration,
            preferences: .init(),
            localURL: nil,
            localMapper: \.message
        )

        let apiManager = APIManager(
            from: API.bundled,
            repository: InMemoryAPIRepository()
        )
        let iapManager = IAPManager(
            customUserLevel: .complete,
            inAppHelper: appConfiguration.makeInAppHelper(),
            receiptReader: FakeInAppReceiptReader(),
            betaChecker: TestFlightChecker(),
            timeoutInterval: appConfiguration.constants.iap.productsTimeoutInterval,
            verificationDelayMinutesBlock: { _ in
                2
            },
            productsAtBuild: { _ in
                []
            }
        )
        let profileProcessor = appConfiguration.makeAppProfileProcessor(
            iapManager: iapManager
        )
        let profileManager: ProfileManager = .forUITesting(
            withRegistry: registry,
            processor: profileProcessor
        )
        profileManager.enableRemoteImporting(true)
        let tunnelProcessor = appConfiguration.makeAppTunnelProcessor(
            apiManager: apiManager,
            resolver: registry,
            extensionInstaller: nil,
            providerServerSorter: {
                $0.sort(using: $1.sortingComparators)
            }
        )
        let tunnel = Tunnel(
            .global,
            strategy: FakeTunnelStrategy(),
            environmentFactory: { @Sendable _ in
                SharedTunnelEnvironment(profileId: nil)
            }
        )
        let tunnelObservable = TunnelObservable(
            tunnel: tunnel,
            willInstall: tunnelProcessor.willInstall
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
            defaults: defaults,
            extensionInstaller: nil,
            iapManager: iapManager,
            preferences: preferences,
            preferencesManager: preferencesManager,
            profileManager: profileManager,
            registry: registry,
            tunnelObservable: tunnelObservable,
            versionChecker: versionChecker,
            webReceiverManager: webReceiverManager
        )
    }
}
