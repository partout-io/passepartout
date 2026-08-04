// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import Partout

extension ModuleType {
    public static let knownTypes: [ModuleType] = [
        .OpenVPN,
        .WireGuard,
        .DNS,
        .HTTPProxy,
        .IP,
        .OnDemand,
        .Provider
    ]

    public static var connectionTypes: [ModuleType] {
        ModuleType.knownTypes.filter(\.isConnection)
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
