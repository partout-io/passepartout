// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import SwiftUI

struct ThemeEmptyMessageModifier: ViewModifier {

    @Environment(Theme.self)
    private var theme

    let fullScreen: Bool

    func body(content: Content) -> some View {
        if fullScreen {
            innerView(content: content)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            innerView(content: content)
        }
    }

    private func innerView(content: Content) -> some View {
        content
            .font(theme.emptyMessageFont)
            .foregroundStyle(theme.emptyMessageColor)
    }
}
