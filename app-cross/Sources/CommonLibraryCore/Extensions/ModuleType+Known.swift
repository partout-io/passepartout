// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import Partout

extension ModuleType: @retroactive CaseIterable {
    public static let allCases: [ModuleType] = {
        var list: [ModuleType] = [
            .OpenVPN,
            .WireGuard,
            .DNS,
            .HTTPProxy,
            .IP,
            .OnDemand
        ]
        list.append(.Provider)
        return list
    }()

    public static var connectionTypes: [ModuleType] {
        ModuleType.allCases.filter(\.isConnection)
    }
}

extension ModuleType {
    public var isConnection: Bool {
        switch self {
        case .OpenVPN, .WireGuard:
            return true
        default:
            return false
        }
    }
}

extension ProviderModule {
    public var buildsConnection: Bool {
        ModuleType.connectionTypes.contains(providerModuleType)
    }
}
