// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonLibrary
import CommonResources
import Foundation

struct Dependencies {
    let appConfiguration: ABI.AppConfiguration

    init(buildTarget: ABI.BuildTarget) {
        appConfiguration = Resources.newAppConfiguration(
            distributionTarget: Self.currentDistributionTarget,
            buildTarget: buildTarget
        )
    }
}

private extension Dependencies {
    static var currentDistributionTarget: ABI.DistributionTarget {
#if PP_BUILD_MAC
        .developerID
#else
        .appStore
#endif
    }
}
