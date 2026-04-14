// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import SwiftUI

public struct ThemeTextField: View {
    let title: String?

    @Binding
    var text: String

    let placeholder: String

    let inputType: ThemeInputType

    let sideAligned: Bool

    public init(
        _ title: String?,
        text: Binding<String>,
        placeholder: String,
        inputType: ThemeInputType = .text,
        sideAligned: Bool = false
    ) {
        self.title = title
        _text = text
        self.placeholder = placeholder
        self.inputType = inputType
        self.sideAligned = sideAligned
    }
}

extension ThemeTextField {
    @ViewBuilder
    var labeledView: some View {
        if let title {
            LabeledContent {
                fieldView
#if os(iOS)
                    .multilineTextAlignment(sideAligned ? .trailing : .leading)
                    .frame(maxWidth: .infinity, alignment: sideAligned ? .trailing : .leading)
#endif
            } label: {
                Text(title)
            }
        } else {
            fieldView
        }
    }

    var fieldView: some View {
        TextField(title ?? "", text: $text, prompt: Text(placeholder))
            .themeManualInput(inputType)
    }
}
