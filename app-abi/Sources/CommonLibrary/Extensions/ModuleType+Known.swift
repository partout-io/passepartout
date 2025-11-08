// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import Foundation

extension ModuleType: @retroactive CaseIterable {
    public static let allCases: [ModuleType] = [
        .openVPN,
        .wireGuard,
        .dns,
        .httpProxy,
        .ip,
        .onDemand,
        .provider
    ]
}

extension ModuleType {
    public var isConnection: Bool {
        switch self {
        case .openVPN, .wireGuard:
            return true
        default:
            return false
        }
    }
}
