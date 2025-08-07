// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#if !os(tvOS)

import SwiftUI

struct ThemeGridSectionModifier<Header>: ViewModifier where Header: View {

    @EnvironmentObject
    private var theme: Theme

    @ViewBuilder
    let header: Header

    func body(content: Content) -> some View {
        header
            .font(theme.gridHeaderStyle)
            .fontWeight(theme.relevantWeight)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.leading)
            .padding(.bottom, theme.gridHeaderBottom)

        content
            .padding(.bottom)
    }
}

#endif
