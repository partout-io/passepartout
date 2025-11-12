// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonLibrary

import Foundation

extension AppFeature: LocalizableEntity {
    public var localizedDescription: String {
        let V = Strings.Features.self
        switch self {
        case .appleTV:
            return V.appletv(Strings.Unlocalized.appleTV)
        case .dns:
            return V.dns
        case .httpProxy:
            return V.httpProxy
        case .onDemand:
            return V.onDemand
        case .otp:
            return Strings.Unlocalized.otp
        case .providers:
            return V.providers
        case .routing:
            return V.routing
        case .sharing:
            return V.sharing(Strings.Unlocalized.iCloud)
        }
    }
}

extension AppFeature: Comparable {
    public static func < (lhs: Self, rhs: Self) -> Bool {
        lhs.localizedDescription.lowercased() < rhs.localizedDescription.lowercased()
    }
}
