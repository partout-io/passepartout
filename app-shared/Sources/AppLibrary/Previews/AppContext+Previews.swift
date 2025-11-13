// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonLibrary
import Foundation

extension AppContext {
    public static let forPreviews: AppContext = {
        let constants: Constants = .shared

        let kvManager = KeyValueManager()
        let iapManager = IAPManager(
            customUserLevel: .complete,
            inAppHelper: FakeAppProductHelper(),
            receiptReader: FakeAppReceiptReader(),
            betaChecker: TestFlightChecker(),
            timeoutInterval: Constants.shared.iap.productsTimeoutInterval,
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
            interval: constants.tunnel.refreshInterval
        )
        let apiManager = APIManager(
            .global,
            from: API.bundled,
            repository: InMemoryAPIRepository(.global)
        )
        let configManager = ConfigManager()
        let preferencesManager = PreferencesManager()
        let registry = Registry()

        let dummyReceiver = DummyWebReceiver(url: URL(string: "http://127.0.0.1:9000")!)
        let webReceiverManager = WebReceiverManager(webReceiver: dummyReceiver, passcodeGenerator: { "123456" })
        let versionChecker = VersionChecker()

        let distributionTarget: DistributionTarget = .appStore

        return AppContext(
            apiManager: apiManager,
            configManager: configManager,
            distributionTarget: distributionTarget,
            iapManager: iapManager,
            kvManager: kvManager,
            preferencesManager: preferencesManager,
            profileManager: profileManager,
            registry: registry,
            sysexManager: nil,
            tunnel: tunnel,
            versionChecker: versionChecker,
            webReceiverManager: webReceiverManager
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
