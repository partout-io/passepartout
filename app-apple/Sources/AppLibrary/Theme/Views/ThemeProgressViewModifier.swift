// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import SwiftUI

struct ThemeProgressViewModifier<EmptyContent>: ViewModifier where EmptyContent: View {
    let isProgressing: Bool

    var isEmpty: Bool?

    var emptyContent: (() -> EmptyContent)?

    func body(content: Content) -> some View {
        ZStack {
            content
                .opaque(!isProgressing && isEmpty != true)

            if isProgressing {
                ThemeProgressView()
            } else if let isEmpty, let emptyContent, isEmpty {
                emptyContent()
            }
        }
    }
}
