// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonLibrary
import SwiftUI

extension EnvironmentValues {
    public var isUITesting: Bool {
        get {
            self[IsUITestingKey.self]
        }
        set {
            self[IsUITestingKey.self] = newValue
        }
    }

    public var distributionTarget: ABI.DistributionTarget {
        get {
            self[DistributionTargetKey.self]
        }
        set {
            self[DistributionTargetKey.self] = newValue
        }
    }
}

private struct IsUITestingKey: EnvironmentKey {
    static let defaultValue = false
}

private struct DistributionTargetKey: EnvironmentKey {
    static let defaultValue: ABI.DistributionTarget = .appStore
}
