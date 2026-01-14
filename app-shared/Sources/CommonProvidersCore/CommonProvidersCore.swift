// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

// FIXME: #1594, Drop this after fixing circular dep on AppLogger
import Partout
extension LoggerCategory {
    public static let providers = LoggerCategory(rawValue: "providers")
}
