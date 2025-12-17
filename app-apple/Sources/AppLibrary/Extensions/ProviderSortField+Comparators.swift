// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonProviders
import Foundation

extension Collection where Element == ProviderSortField {
    public var sortingComparators: [KeyPathComparator<ProviderServer>] {
        map {
            switch $0 {
            case .localizedCountry:
                return KeyPathComparator(\.localizedCountry)
            case .area:
                return KeyPathComparator(\.metadata.area)
            case .serverId:
                return KeyPathComparator(\.serverId)
            }
        }
    }
}
