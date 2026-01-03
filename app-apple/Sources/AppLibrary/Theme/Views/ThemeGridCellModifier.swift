// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#if !os(tvOS)

import SwiftUI

struct ThemeGridCellModifier: ViewModifier {

    @Environment(Theme.self)
    private var theme

    func body(content: Content) -> some View {
        content
            .padding()
            .background(theme.gridCellColor)
            .clipShape(.rect(cornerRadius: theme.gridRadius))
    }
}

#endif
