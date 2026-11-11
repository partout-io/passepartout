// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import SwiftUI

struct ThemeGradientModifier: ViewModifier {
    @Environment(Theme.self)
    private var theme

    func body(content: Content) -> some View {
        content
            .background(theme.darkAccentColor.opacity(0.6).gradient)
    }
}
