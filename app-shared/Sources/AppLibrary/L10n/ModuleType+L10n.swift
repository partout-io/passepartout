// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonLibrary
import Foundation

extension ModuleType: LocalizableEntity {
    public var localizedDescription: String {
        switch self {
        case .openVPN:
            return Strings.Unlocalized.openVPN

        case .wireGuard:
            return Strings.Unlocalized.wireGuard

        case .dns:
            return Strings.Unlocalized.dns

        case .httpProxy:
            return Strings.Unlocalized.httpProxy

        case .ip:
            return Strings.Global.Nouns.routing

        case .onDemand:
            return Strings.Global.Nouns.onDemand

        case .provider:
            return Strings.Global.Nouns.provider

        default:
            assertionFailure("Missing localization for ModuleType: \(rawValue)")
            return rawValue
        }
    }
}

extension ModuleType: @retroactive Comparable {
    public static func < (lhs: Self, rhs: Self) -> Bool {
        lhs.localizedDescription.lowercased() < rhs.localizedDescription.lowercased()
    }
}
