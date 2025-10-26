// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import Foundation

// order matters
public enum ProfilesLayout: String, RawRepresentable, CaseIterable, Codable {
    case list

    case grid
}
