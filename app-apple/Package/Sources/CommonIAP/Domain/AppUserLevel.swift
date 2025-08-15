// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import Foundation

public enum AppUserLevel: Int, Sendable {
    case undefined = -1

    case freemium = 0

    case beta = 1

    case essentials = 2 // without .appleTV and future features

    case complete = 3
}

extension AppUserLevel {
    public var isBeta: Bool {
        self == .beta
    }
}
