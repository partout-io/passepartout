// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

// Order matters
public enum ProfilesLayout: String, RawRepresentable, CaseIterable, Codable {
    case list
    case grid
}
