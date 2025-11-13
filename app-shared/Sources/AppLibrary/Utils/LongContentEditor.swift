// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#if !os(tvOS)

import CommonLibrary
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
                    Utils.copyToPasteboard(content)
                } label: {
                    Image(systemName: copySystemImage ?? "doc.on.doc")
                }
            }
    }

    @ViewBuilder
    private var contentView: some View {
        if #available(iOS 17, macOS 14, *) {
            TextEditor(text: $content)
                .scrollClipDisabled()
        } else {
            TextEditor(text: $content)
        }
    }
}

#endif
