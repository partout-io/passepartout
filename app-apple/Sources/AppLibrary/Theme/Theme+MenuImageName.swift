// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import Foundation

extension Theme {
    public enum MenuImageName {
        case active
        case inactive
        case pending
    }
}

extension Theme.MenuImageName {
    static var defaultImageName: (Self) -> String {
        {
            switch $0 {
            case .active: return "MenuActive"
            case .inactive: return "MenuInactive"
            case .pending: return "MenuPending"
            }
        }
    }
}
