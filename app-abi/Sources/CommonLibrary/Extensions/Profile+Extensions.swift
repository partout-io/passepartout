// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import Foundation

extension Profile {
    public static func sorting(lhs: Self, rhs: Self) -> Bool {
        lhs.name.lowercased() < rhs.name.lowercased()
    }
}
