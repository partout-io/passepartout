// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#if !os(tvOS)

import SwiftUI

public struct ThemeDisclosableMenu<Content, Label>: View where Content: View, Label: View {

    @ViewBuilder
    private let content: () -> Content

    @ViewBuilder
    private let label: () -> Label

    public init(content: @escaping () -> Content, label: @escaping () -> Label) {
        self.content = content
        self.label = label
    }

    public var body: some View {
        Menu(content: content) {
            HStack(alignment: .firstTextBaseline) {
                label()
                ThemeImage(.disclose)
                    .foregroundStyle(.secondary)
            }
            .contentShape(.rect)
        }
        .foregroundStyle(.primary)
#if os(macOS)
        .buttonStyle(.plain)
#endif
        .cursor(.hand)
    }
}

#endif
