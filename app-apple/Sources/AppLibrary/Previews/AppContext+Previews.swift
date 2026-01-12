// SPDX-FileCopyrightText: 2026 Davide De Rosa
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
        let appLogger = appConfiguration.newAppLogger()
        let logFormatter = DummyLogFormatter()
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
            inAppHelper: FakeInAppHelper(),
            receiptReader: FakeInAppReceiptReader(),
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
        let tunnel = Tunnel(.global, strategy: FakeTunnelStrategy()) { _ in
            SharedTunnelEnvironment(profileId: nil)
        }
        let tunnelManager = TunnelManager(
            tunnel: tunnel,
            processor: processor,
            interval: 10.0
        )
        let preferencesManager = PreferencesManager()

        let dummyReceiver = DummyWebReceiver(url: URL(string: "http://127.0.0.1:9000")!)
        let webReceiverManager = WebReceiverManager(webReceiver: dummyReceiver, passcodeGenerator: { "123456" })
        let versionChecker = VersionChecker()

        Task {
            try await profileManager.observeRemote(repository: InMemoryProfileRepository())
        }

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
    }()
}

// MARK: - Shortcuts

extension IAPObservable {
    public static var forPreviews: IAPObservable {
        AppContext.forPreviews.iapObservable
    }
}

extension ProfileObservable {
    public static var forPreviews: ProfileObservable {
        AppContext.forPreviews.profileObservable
    }
}

extension RegistryObservable {
    public static var forPreviews: RegistryObservable {
        AppContext.forPreviews.registryObservable
    }
}

extension TunnelObservable {
    public static var forPreviews: TunnelObservable {
        AppContext.forPreviews.tunnelObservable
    }
}

extension WebReceiverObservable {
    public static var forPreviews: WebReceiverObservable {
        AppContext.forPreviews.webReceiverObservable
    }
}

// MARK: - Shortcuts (deprecated)

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

extension TunnelManager {
    public static var forPreviews: TunnelManager {
        AppContext.forPreviews.tunnel
    }
}

extension APIManager {
    public static var forPreviews: APIManager {
        AppContext.forPreviews.apiManager
    }
}

extension WebReceiverManager {
    public static let forPreviews = WebReceiverManager()
}
