// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import SwiftUI

public struct ThemeNavigatingButton<Label>: View where Label: View {
    private let action: () -> Void

    private let label: () -> Label

    public init(action: @escaping () -> Void, label: @escaping () -> Label) {
        self.action = action
        self.label = label
    }

    public var body: some View {
        Button(action: action) {
            HStack {
                label()
                ThemeImage(.navigate)
                    .foregroundStyle(.secondary)
            }
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .cursor(.hand)
    }
}

extension ThemeNavigatingButton where Label == Text {
    public init(_ title: String, action: @escaping () -> Void) {
        self.init(action: action) {
            Text(title)
        }
    }
}
