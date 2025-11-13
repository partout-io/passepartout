// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import Foundation

public struct ThemeModalOptions: Hashable {
    public var size: ThemeModalSize

    public var isFixedWidth: Bool

    public var isFixedHeight: Bool

    public var isInteractive: Bool

    public init(
        size: ThemeModalSize = .medium,
        isFixedWidth: Bool = false,
        isFixedHeight: Bool = false,
        isInteractive: Bool = true
    ) {
        self.size = size
        self.isFixedWidth = isFixedWidth
        self.isFixedHeight = isFixedHeight
        self.isInteractive = isInteractive
    }
}

public enum ThemeModalSize: Hashable {
    case small

    case medium

    case large

    case custom(width: CGFloat, height: CGFloat)
}

extension ThemeModalSize {
    var defaultSize: CGSize {
        switch self {
        case .small:
            return CGSize(width: 300, height: 300)

        case .medium:
            return CGSize(width: 550, height: 350)

        case .large:
            return CGSize(width: 800, height: 500)

        case .custom(let width, let height):
            return CGSize(width: width, height: height)
        }
    }
}
