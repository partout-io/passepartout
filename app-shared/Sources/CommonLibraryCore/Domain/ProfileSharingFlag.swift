// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

extension ABI {
    public enum ProfileSharingFlag: Int, Codable, Sendable {
        case disabled
        case shared
        case tv

        public var isEnabled: Bool {
            self != .disabled
        }
    }
}
