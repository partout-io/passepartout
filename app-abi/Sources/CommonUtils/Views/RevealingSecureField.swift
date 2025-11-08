// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import SwiftUI

public struct RevealingSecureField<ImageView>: View where ImageView: View {
    public let title: String

    @Binding
    private var text: String

    private var prompt: Text?

    private let conceilImage: () -> ImageView

    private let revealImage: () -> ImageView

    @State
    private var isRevealed = false

    public init(
        _ title: String,
        text: Binding<String>,
        prompt: Text? = nil,
        conceilImage: @escaping () -> ImageView,
        revealImage: @escaping () -> ImageView
    ) {
        self.title = title
        _text = text
        self.prompt = prompt
        self.conceilImage = conceilImage
        self.revealImage = revealImage
    }

    public var body: some View {
        HStack {
            if isRevealed {
                TextField(title, text: $text, prompt: prompt)
                Button {
                    isRevealed.toggle()
                } label: {
                    conceilImage()
                }
                .buttonStyle(.borderless)
            } else {
                SecureField(title, text: $text, prompt: prompt)
                Button {
                    isRevealed.toggle()
                } label: {
                    revealImage()
                }
                .buttonStyle(.borderless)
            }
        }
    }
}

#Preview {
    Form {
        TextField("text", text: .constant("plain-text"))
        RevealingSecureField("secure", text: .constant("secure-text")) {
            Image(systemName: "eye.slash")
        } revealImage: {
            Image(systemName: "eye")
        }
    }
    .formStyle(.grouped)
}
