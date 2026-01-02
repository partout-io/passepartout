// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonProviders
import Foundation

extension ProviderServer {
    public var localizedCountry: String? {
        metadata.countryCode.localizedAsRegionCode
    }

    public var address: String {
        if let hostname {
            return hostname
        }
        if let ipAddresses {
            return ipAddresses
                .compactMap {
                    guard let address = Address(data: $0) else {
                        return nil
                    }
                    return address.description
                }
                .joined(separator: ", ")
        }
        return ""
    }
}

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
