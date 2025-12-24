// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import AppResources
import CommonLibrary
import Partout

extension AppContext {
    public static let forPreviews: AppContext = {
        let appConfiguration = Resources.newAppConfiguration(
            distributionTarget: .appStore,
            buildTarget: .app
        )
        let appLogger = PartoutLoggerStrategy { _, _ in "" }
        let registry = Registry()
        let appEncoder = AppEncoder(registry: registry)
        let kvStore = InMemoryStore()
        let configManager = ConfigManager()
        let apiManager = APIManager(
            .global,
            from: API.bundled,
            repository: InMemoryAPIRepository(.global)
        )
        let iapManager = IAPManager(
            customUserLevel: .complete,
            inAppHelper: FakeAppProductHelper(),
            receiptReader: FakeAppReceiptReader(),
            betaChecker: TestFlightChecker(),
            timeoutInterval: 5.0,
            verificationDelayMinutesBlock: { _ in
                2
            },
            productsAtBuild: { _ in
                []
            }
        )
        let processor = MockAppProcessor(iapManager: iapManager)
        let profileManager = {
            let profiles: [Profile] = (0..<20)
                .reduce(into: []) { list, _ in
                    list.append(.newMockProfile())
                }
            return ProfileManager(profiles: profiles)
        }()
        let tunnel = ExtendedTunnel(
            tunnel: Tunnel(.global, strategy: FakeTunnelStrategy()) { _ in
                SharedTunnelEnvironment(profileId: nil)
            },
            processor: processor,
            interval: 10.0
        )
        let preferencesManager = PreferencesManager()

        let dummyReceiver = DummyWebReceiver(url: URL(string: "http://127.0.0.1:9000")!)
        let webReceiverManager = WebReceiverManager(webReceiver: dummyReceiver, passcodeGenerator: { "123456" })
        let versionChecker = VersionChecker()

        // View
        let userPreferences = UserPreferencesObservable(kvStore: kvStore)

        let abi = CommonABI(
            apiManager: apiManager,
            appConfiguration: appConfiguration,
            appEncoder: appEncoder,
            configManager: configManager,
            iapManager: iapManager,
            kvStore: kvStore,
            logger: appLogger,
            preferencesManager: preferencesManager,
            profileManager: profileManager,
            registry: registry,
            sysexManager: nil,
            tunnel: tunnel,
            versionChecker: versionChecker,
            webReceiverManager: webReceiverManager
        )
        return AppContext(
            abi: abi,
            userPreferences: userPreferences
        )
    }()
}

// MARK: - Shortcuts

extension IAPManager {
    public static var forPreviews: IAPManager {
        AppContext.forPreviews.iapManager
    }
}

extension ProfileManager {
    public static var forPreviews: ProfileManager {
        AppContext.forPreviews.profileManager
    }
}

extension ExtendedTunnel {
    public static var forPreviews: ExtendedTunnel {
        AppContext.forPreviews.tunnel
    }
}

extension APIManager {
    public static var forPreviews: APIManager {
        AppContext.forPreviews.apiManager
    }
}

extension WebReceiverManager {
    public static var forPreviews: WebReceiverManager {
        AppContext.forPreviews.webReceiverManager
    }
}
