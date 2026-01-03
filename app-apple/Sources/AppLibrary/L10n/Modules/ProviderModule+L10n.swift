// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonLibrary
import Partout

extension ProviderID: CustomDebugStringConvertible {
    public var debugDescription: String {
        rawValue
    }
}

extension ProviderEntity: LocalizableEntity {
    public var localizedDescription: String {
        heuristic?.localizedDescription ?? server.localizedDescription
    }
}

extension ProviderHeuristic: LocalizableEntity {
    public var localizedDescription: String {
        switch self {
        case .exact(let server):
            return server.localizedDescription
        case .sameCountry(let countryCode):
            return countryCode.localizedAsRegionCode ?? countryCode
        case .sameRegion(let region):
            return region.localizedDescription
        }
    }
}

extension ProviderRegion: LocalizableEntity {
    public var localizedDescription: String {
        [countryCode.localizedAsRegionCode, area]
            .compactMap { $0 }
            .joined(separator: ", ")
    }
}

extension ProviderServer: LocalizableEntity {
    public var localizedDescription: String {
        [metadata.countryCode.localizedAsRegionCode, metadata.area]
            .compactMap { $0 }
            .joined(separator: ", ")
    }
}
