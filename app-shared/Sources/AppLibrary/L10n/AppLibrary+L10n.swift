// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import Foundation

extension SystemAppearance {
    public var localizedDescription: String {
        let V = Strings.Entities.Ui.SystemAppearance.self
        switch self {
//        case .none: return V.system
        case .light: return V.light
        case .dark: return V.dark
        }
    }
}
