// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

public enum ThemeInputType {
    case ipAddress
    case number
    case text
}

#if os(iOS) || os(tvOS)

import SwiftUI

extension ThemeInputType {
    var keyboardType: UIKeyboardType {
        switch self {
        case .ipAddress: .numbersAndPunctuation
        case .number: .numberPad
        case .text: .default
        }
    }
}

#endif
