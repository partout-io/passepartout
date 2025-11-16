// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonLibrary
import Foundation

@MainActor
struct Dependencies {
    static let shared = Dependencies()
}

extension Dependencies {
    public nonisolated static var distributionTarget: ABI.DistributionTarget {
#if PP_BUILD_MAC
        .developerID
#else
        .appStore
#endif
    }
}
