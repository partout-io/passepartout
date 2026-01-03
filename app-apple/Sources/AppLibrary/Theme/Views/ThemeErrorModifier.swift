// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import SwiftUI

struct ThemeErrorModifier: ViewModifier {

    @Environment(Theme.self)
    private var theme

    let isError: Bool

    func body(content: Content) -> some View {
        content
            .foregroundStyle(isError ? theme.errorColor : theme.titleColor)
    }
}
