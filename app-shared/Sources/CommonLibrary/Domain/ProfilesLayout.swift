// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

// Order matters
extension ABI {
    public enum ProfilesLayout: String, RawRepresentable, CaseIterable, Codable {
        case list
        case grid
    }
}
