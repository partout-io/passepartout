// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import Foundation
import Partout

extension OnDemandModule.Policy: LocalizableEntity {
    public var localizedDescription: String {
        switch self {
        case .any:
            return Strings.Entities.OnDemand.Policy.any
        case .excluding:
            return Strings.Entities.OnDemand.Policy.excluding
        case .including:
            return Strings.Entities.OnDemand.Policy.including
        @unknown default:
            return Strings.Entities.OnDemand.Policy.any
        }
    }
}
