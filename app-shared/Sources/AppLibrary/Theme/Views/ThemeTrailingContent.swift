// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#if !os(tvOS)

import SwiftUI

public struct ThemeTrailingContent<Content>: View where Content: View {

    @ViewBuilder
    private let content: () -> Content

    public init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content
    }

    public var body: some View {
#if os(iOS)
        content()
            .frame(maxWidth: .infinity)
#else
        HStack {
            Spacer()
            content()
        }
#endif
    }
}

#endif
