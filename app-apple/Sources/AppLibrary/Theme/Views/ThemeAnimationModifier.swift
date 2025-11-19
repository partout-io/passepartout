// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import SwiftUI

struct ThemeAnimationModifier<T>: ViewModifier where T: Equatable {

    @Environment(Theme.self)
    private var theme

    let value: T

    let category: ThemeAnimationCategory

    func body(content: Content) -> some View {
        content
            .animation(theme.animation(for: category), value: value)
    }
}
