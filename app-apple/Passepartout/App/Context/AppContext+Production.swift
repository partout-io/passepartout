// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

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
        let abi = AppABI.forProduction(appConfiguration: appConfiguration, kvStore: kvStore)
        return AppContext(abi: abi, appConfiguration: appConfiguration, kvStore: kvStore)
    }
}
