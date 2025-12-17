// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

extension ModuleType: @retroactive CaseIterable {
    public static let allCases: [ModuleType] = {
        var list: [ModuleType] = [
            .openVPN,
            .wireGuard,
            .dns,
            .httpProxy,
            .ip,
            .onDemand
        ]
#if PSP_PROVIDERS
        list.append(.provider)
#endif
        return list
    }()
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
