// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

extension ABI {
    public enum ProfileSharingFlag: Int, Codable, Sendable {
        case shared = 1
        case tv
    }
}
