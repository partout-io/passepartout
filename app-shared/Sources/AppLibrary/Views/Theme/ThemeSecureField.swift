// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonLibrary
import SwiftUI

public struct ThemeSecureField: View {
    let title: String?

    @Binding
    var text: String

    let placeholder: String

    public init(title: String?, text: Binding<String>, placeholder: String) {
        self.title = title
        _text = text
        self.placeholder = placeholder
    }

    @ViewBuilder
    var labeledView: some View {
        if let title {
            LabeledContent {
                fieldView
            } label: {
                Text(title)
            }
        } else {
            fieldView
        }
    }

    var fieldView: some View {
        RevealingSecureField(title ?? "", text: $text, prompt: Text(placeholder)) {
           ThemeImage(.hide)
                .foregroundStyle(Color.accentColor)
       } revealImage: {
           ThemeImage(.show)
               .foregroundStyle(Color.accentColor)
       }
    }
}
