// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#if !os(tvOS)

import SwiftUI

public struct LongContentEditor: View {

    @Binding
    private var content: String

    private let copySystemImage: String?

    public init(content: Binding<String>, copySystemImage: String? = nil) {
        _content = content
        self.copySystemImage = copySystemImage
    }

    public var body: some View {
        contentView
            .toolbar {
                Button {
                    copyToPasteboard(content)
                } label: {
                    Image(systemName: copySystemImage ?? "doc.on.doc")
                }
            }
    }

    private var contentView: some View {
        TextEditor(text: $content)
            .scrollClipDisabled()
    }
}

#endif
