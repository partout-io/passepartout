// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#if !os(tvOS)

import SwiftUI

struct ThemeTipModifier<Label>: ViewModifier where Label: View {
    let text: String

    let edge: Edge

    let width: Double

    let alignment: Alignment

    let label: () -> Label

    @State
    private var isPresenting = false

    func body(content: Content) -> some View {
        HStack {
            content
            Button {
                isPresenting = true
            } label: {
                label()
            }
            .buttonStyle(.borderless)
            .popover(isPresented: $isPresenting, arrowEdge: edge) {
                VStack {
                    Text(text)
                        .font(.body)
                        .foregroundStyle(.primary)
                        .lineLimit(nil)
                        .multilineTextAlignment(.leading)
                        .frame(width: width, alignment: alignment)
                }
                .padding(12)
            }
        }
    }
}

#endif
