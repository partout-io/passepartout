// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import SwiftUI

public struct ThemeFullScreenView<Icon>: View where Icon: View {

    @EnvironmentObject
    private var theme: Theme

    @Environment(\.colorScheme)
    private var colorScheme

    @ViewBuilder
    private let icon: () -> Icon

    public init(icon: @escaping () -> Icon) {
        self.icon = icon
    }

    public var body: some View {
        ZStack {
            theme.backgroundColor(colorScheme)
                .ignoresSafeArea()
            icon()
        }
        .ignoresSafeArea()
    }
}

#Preview {
    ThemeFullScreenView {
        ThemeImage(.cloudOn)
            .foregroundStyle(.white)
    }
    .withMockEnvironment()
}
