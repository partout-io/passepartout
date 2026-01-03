// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import SwiftUI

struct ListRowView<Content>: View where Content: View {

    @Environment(Theme.self)
    private var theme

    let title: String

    @ViewBuilder
    let content: Content

    var body: some View {
        HStack {
            Text(title)
                .fontWeight(theme.secondaryWeight)
            Spacer()
            content
        }
    }
}
