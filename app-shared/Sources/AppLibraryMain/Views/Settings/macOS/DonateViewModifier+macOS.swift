// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#if os(macOS)

import SwiftUI

struct DonateViewModifier: ViewModifier {
    func body(content: Content) -> some View {
        Form {
            Section {
                Text(Strings.Views.Donate.Sections.Main.footer)
            }
            content
        }
        .themeForm()
    }
}

#endif
