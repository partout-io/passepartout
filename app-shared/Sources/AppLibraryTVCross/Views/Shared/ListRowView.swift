// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import SwiftUI

struct ListRowView<Content>: View where Content: View {

    @EnvironmentObject
    private var theme: Theme

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
