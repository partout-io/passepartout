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
        list.append(.provider)
        return list
    }()
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
