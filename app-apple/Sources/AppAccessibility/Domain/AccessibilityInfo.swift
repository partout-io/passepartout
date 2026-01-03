// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import Foundation

public struct AccessibilityInfo: Equatable, Sendable {
    public enum ElementType: Sendable {
        case button

        case link

        case menu

        case menuItem

        case text

        case toggle
    }

    public let id: String

    public let elementType: ElementType

    public init(_ id: String, _ elementType: ElementType) {
        self.id = id
        self.elementType = elementType
    }

    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.id == rhs.id
    }
}
