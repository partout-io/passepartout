// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import SwiftUI

struct DonateViewModifier: ViewModifier {
    func body(content: Content) -> some View {
        VStack {
            TopSpacer()
            Text(Strings.Views.Donate.Sections.Main.footer)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.bottom)

            ScrollView {
                LazyVGrid(columns: columns) {
                    content
                }
            }
        }
    }
}

private extension DonateViewModifier {
    var columns: [GridItem] {
        [GridItem(.adaptive(minimum: 300))]
    }
}
