// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import SwiftUI

@MainActor @Observable
public final class Theme {
    private var animation: Animation = .spring

    public internal(set) var animationCategories: Set<ThemeAnimationCategory> = Set(ThemeAnimationCategory.allCases)

    public internal(set) var relevantWeight: Font.Weight = .semibold

    public internal(set) var secondaryWeight: Font.Weight = .light

    public internal(set) var titleColor: Color = .primary

    public internal(set) var valueColor: Color = .secondary

    public internal(set) var gridHeaderStyle: Font = .headline

    public internal(set) var gridRadius: CGFloat = 12.0

    public internal(set) var gridHeaderBottom: CGFloat = 8.0

    public internal(set) var gridCellColor: HierarchicalShapeStyle = .quinary

    public internal(set) var gridCellActiveColor: HierarchicalShapeStyle = .quaternary

    public internal(set) var emptyMessageFont: Font = .title

    public internal(set) var emptyMessageColor: Color = .secondary

    public internal(set) var lightAccentColor: Color = .accentColor // gold

    public internal(set) var darkAccentColor = Color(hex: 0x515d70) // blue

    public internal(set) var activeColor = Color(hex: 0x00aa00)

    public internal(set) var inactiveColor: Color = .secondary

    public internal(set) var pendingColor: Color = .orange

    public internal(set) var errorColor: Color = .red

    public var enableColor: Color {
        activeColor
    }

    public var disableColor: Color {
        errorColor
    }

    public var upgradeColor: Color {
        pendingColor
    }

    public func backgroundColor(_ scheme: ColorScheme) -> Color {
        switch scheme {
        case .dark:
#if os(iOS)
            return Color(.systemBackground)
#elseif os(macOS)
            return Color(.windowBackgroundColor)
#else
            return .black
#endif
        default:
            return darkAccentColor
        }
    }

    public internal(set) var logoImage = "Logo"

    public internal(set) var modalSize: (ThemeModalSize) -> CGSize = {
        $0.defaultSize
    }

    public internal(set) var systemImageName: (ImageName) -> String = Theme.ImageName.defaultSystemName

    public internal(set) var menuImageName: (MenuImageName) -> String = Theme.MenuImageName.defaultImageName

    init(dummy: Void) {
    }

    public func animation(for category: ThemeAnimationCategory) -> Animation? {
        animationCategories.contains(category) ? animation : nil
    }
}
