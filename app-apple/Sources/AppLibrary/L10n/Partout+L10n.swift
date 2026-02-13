// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonLibrary
import Foundation

// MARK: Profile

extension ABI.AppProfileHeader: StyledOptionalLocalizableEntity {
    public enum OptionalStyle {
        case primaryType
        case secondaryTypes
    }

    public func localizedDescription(optionalStyle: OptionalStyle) -> String? {
        switch optionalStyle {
        case .primaryType:
            return primaryModuleType?.localizedDescription
        case .secondaryTypes:
            return secondaryModuleTypes?
                .map(\.localizedDescription)
                .sorted()
                .joined(separator: ", ")
        }
    }
}

// MARK: - Modules

extension ModuleBuilder {
    @MainActor
    public func description(inEditor editor: ProfileEditor) -> String {
        moduleType.localizedDescription
    }
}

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

// MARK: - Misc

extension TunnelStatus: LocalizableEntity {
    public var localizedDescription: String {
        let V = Strings.Entities.TunnelStatus.self
        switch self {
        case .inactive:
            return V.inactive
        case .activating:
            return V.activating
        case .active:
            return V.active
        case .deactivating:
            return V.deactivating
        }
    }
}

extension DataCount: LocalizableEntity {
    public var localizedDescription: String {
        let down = received.descriptionAsDataUnit
        let up = sent.descriptionAsDataUnit
        return "↓\(down) ↑\(up)"
    }
}

extension Address.Family: LocalizableEntity {
    public var localizedDescription: String {
        switch self {
        case .v4:
            return Strings.Unlocalized.ipv4
        case .v6:
            return Strings.Unlocalized.ipv6
        }
    }
}

extension IPSettings: StyledOptionalLocalizableEntity {
    public enum OptionalStyle {
        case address
        case defaultGateway
    }

    public func localizedDescription(optionalStyle: OptionalStyle) -> String? {
        switch optionalStyle {
        case .address:
            return addressDescription
        case .defaultGateway:
            return defaultGatewayDescription
        }
    }

    private var addressDescription: String? {
        subnets.first?.address.rawValue
    }

    private var defaultGatewayDescription: String? {
        includedRoutes
            .first(where: \.isDefault)?
            .gateway?
            .rawValue
    }
}

extension Route: LocalizableEntity {
    public var localizedDescription: String {
        if let dest = destination?.rawValue {
            if let gw = gateway?.rawValue {
                return "\(dest) → \(gw)"
            } else {
                return dest
            }
        } else if let gw = gateway?.rawValue {
            return "default → \(gw)"
        }
        return "default → *"
    }
}
