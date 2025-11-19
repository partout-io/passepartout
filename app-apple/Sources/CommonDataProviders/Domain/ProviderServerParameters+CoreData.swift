// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonLibrary
import Foundation

extension ProviderID {
    var predicate: NSPredicate {
        NSPredicate(format: predicateFormat, predicateArg)
    }

    fileprivate var predicateFormat: String {
        "providerId == %@"
    }

    fileprivate var predicateArg: String {
        rawValue
    }
}

extension ProviderSortField {
    var sortDescriptor: NSSortDescriptor {
        switch self {
        case .localizedCountry:
            return NSSortDescriptor(key: "localizedCountry", ascending: true)

        case .area:
            return NSSortDescriptor(key: "area", ascending: true)

        case .serverId:
            return NSSortDescriptor(key: "serverId", ascending: true)

        @unknown default:
            return NSSortDescriptor()
        }
    }
}

extension ProviderFilters {
    func predicate(for providerId: ProviderID) -> NSPredicate {
        var formats: [String] = []
        var args: [Any] = []

        formats.append(providerId.predicateFormat)
        args.append(providerId.rawValue)

        if let moduleType {
            formats.append("supportedModuleTypes contains %@")
            args.append(moduleType.rawValue)
        }
        if let presetId {
            formats.append("(supportedPresetIds == NULL OR supportedPresetIds contains %@)")
            args.append(presetId)
        }
        if let categoryName {
            formats.append("categoryName == %@")
            args.append(categoryName)
        }
        if let countryCode {
            formats.append("countryCode == %@")
            args.append(countryCode)
        }
        if let area {
            formats.append("area == %@")
            args.append(area)
        }

        let format = formats.joined(separator: " AND ")
        return NSPredicate(format: format, argumentArray: args)
    }
}
