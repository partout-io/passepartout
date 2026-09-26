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
        let appImportExport: AppImportExport = .dummy
        let preferences = AppPreferencesStore()
        let defaults = UserDefaults()

        pspLogRegister(
            for: .app,
            with: appConfiguration,
            preferences: .init(),
            localURL: nil,
            localMapper: \.message
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
        let mainProfileRepository = InMemoryProfileRepository()
        let wireGuardKeyGenerator = FakeWireGuardKeyGenerator()
        let profileManager: ProfileManager = .forUITesting(
            withNewModule: {
                RegistryObservable(
                    wireGuardKeyGenerator: wireGuardKeyGenerator,
                    wireGuardValidateBlock: { _ in }
                )
                .newModule(ofType: $0)
            },
            processor: profileProcessor,
            repository: mainProfileRepository
        )
        profileManager.enableRemoteImporting(true)
        let tunnelProcessor = appConfiguration.makeAppTunnelProcessor(
            profileRepository: mainProfileRepository,
            extensionInstaller: nil
        )
        let tunnel = PartoutTunnel(
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
            appConfiguration: appConfiguration,
            appImportExport: appImportExport,
            configManager: configManager,
            defaults: defaults,
            extensionInstaller: nil,
            iapManager: iapManager,
            preferences: preferences,
            preferencesManager: preferencesManager,
            profileManager: profileManager,
            tunnelObservable: tunnelObservable,
            versionChecker: versionChecker,
            webReceiverManager: webReceiverManager,
            wireGuardKeyGenerator: wireGuardKeyGenerator
        )
    }
}
