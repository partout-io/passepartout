// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import SwiftUI

struct ThemeTrailingValueModifier: ViewModifier {
    let value: CustomStringConvertible?

    let truncationMode: Text.TruncationMode

    func body(content: Content) -> some View {
        LabeledContent {
            if let value {
                Text(value.description)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(truncationMode)
            }
        } label: {
            content
        }
    }
}
