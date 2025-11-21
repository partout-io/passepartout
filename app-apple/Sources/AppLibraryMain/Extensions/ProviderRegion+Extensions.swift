// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonLibrary
import Foundation

extension ProviderServer {
    var region: ProviderRegion {
        ProviderRegion(countryCode: metadata.countryCode, area: metadata.area)
    }
}

extension String {
    func isCountryCodeSelected(by heuristic: ProviderHeuristic?) -> Bool {
        guard let heuristic else {
            return false
        }
        switch heuristic {
        case .exact(let server):
            return self == server.metadata.countryCode
        case .sameCountry(let code):
            return self == code
        case .sameRegion(let region):
            return self == region.countryCode
        }
    }
}

extension ProviderRegion {
    func isSelected(by heuristic: ProviderHeuristic?) -> Bool {
        guard let heuristic else {
            return false
        }
        switch heuristic {
        case .exact(let server):
            return id == server.regionId
        case .sameCountry(let code):
            return countryCode == code && area == nil
        case .sameRegion(let region):
            return id == region.id
        }
    }
}

extension Collection where Element == ProviderServer {

    // TODO: #1263, drop this later, fetch regions directly from Core Data
    var regions: [ProviderRegion] {
        var list: [ProviderRegion] = []
        var added: Set<String> = []
        forEach {
            let regionId = $0.regionId
            if !added.contains(regionId) {
                added.insert(regionId)
                if $0.metadata.area != nil {
                    let anyRegion = ProviderRegion(countryCode: $0.metadata.countryCode, area: nil)
                    if !added.contains(anyRegion.id) {
                        added.insert(anyRegion.id)
                        list.append(anyRegion)
                    }
                }
                list.append($0.region)
            }
        }
        return list
    }

    func randomServer(using heuristic: ProviderHeuristic) -> ProviderServer? {
        filter(heuristic.matches)
            .randomElement()
    }
}
