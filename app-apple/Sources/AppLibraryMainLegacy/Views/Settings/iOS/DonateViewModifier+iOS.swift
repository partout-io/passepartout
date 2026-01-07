// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#if os(iOS)

import SwiftUI

struct DonateViewModifier: ViewModifier {
    func body(content: Content) -> some View {
        List {
            content
                .themeSection(footer: Strings.Views.Donate.Sections.Main.footer)
        }
    }
}

#endif
