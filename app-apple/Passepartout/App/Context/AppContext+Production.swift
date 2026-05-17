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
        // Fetch bundle and constants
        let appConfiguration = Resources.newAppConfiguration(
            distributionTarget: distributionTarget,
            buildTarget: .app
        )
        // Create ABI returning Tunnel to build TunnelObservable
        let kvStore = appConfiguration.newKeyValueStore()
        let sysexManager = appConfiguration.newSystemExtensionManager()
        let result = AppABI.forNetworkExtension(
            appConfiguration: appConfiguration,
            kvStore: kvStore,
            sysexManager: sysexManager,
            assertModule: { moduleType, registry in
#if !os(tvOS)
                let builder = registry.newModule(ofType: moduleType)
                assert(builder is any ModuleViewProviding, "\(moduleType): is not ModuleViewProviding")
#endif
            },
            apiMappers: API.shared,
            webHTMLPath: Resources.webUploaderPath,
            webStringsBundle: AppStrings.bundle,
            withUITesting: AppCommandLine.contains(.uiTesting),
            withFakeIAPs: AppCommandLine.contains(.fakeIAP)
        )
        return AppContext(
            abi: result.abi,
            appConfiguration: appConfiguration,
            kvStore: kvStore,
            tunnel: result.tunnel,
            sysexManager: sysexManager
        )
    }
}
