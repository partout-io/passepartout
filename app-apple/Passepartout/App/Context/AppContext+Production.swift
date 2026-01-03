// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import AppAccessibility
import AppLibrary
import AppResources
import CommonLibrary

extension AppContext {
    static func forProduction() -> AppContext {
        let distributionTarget: ABI.DistributionTarget
#if PP_BUILD_MAC
        distributionTarget = .developerID
#else
        distributionTarget = .appStore
#endif
        let appConfiguration = Resources.newAppConfiguration(
            distributionTarget: distributionTarget,
            buildTarget: .app
        )
        let kvStore = appConfiguration.newKeyValueStore()
        let abi = AppABI.forProduction(
            appConfiguration: appConfiguration,
            kvStore: kvStore,
            assertModule: { moduleType, registry in
                let builder = moduleType.newModule(with: registry)
                guard builder is any ModuleViewProviding else {
                    fatalError("\(moduleType): is not ModuleViewProviding")
                }
            },
            profilePreview: \.localizedPreview,
            apiMappers: API.shared,
            webHTMLPath: Resources.webUploaderPath,
            webStringsBundle: AppStrings.bundle,
            withUITesting: AppCommandLine.contains(.uiTesting),
            withFakeIAPs: AppCommandLine.contains(.fakeIAP)
        )
        return AppContext(abi: abi, appConfiguration: appConfiguration, kvStore: kvStore)
    }
}
