// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#if !os(tvOS)

import CommonLibrary
import SwiftUI

public struct ThemeLongContentLink: View {
    private let title: String

    @Binding
    private var text: String

    private let preview: String?

    private let inputType: ThemeInputType

    public init(
        _ title: String,
        text: Binding<String>,
        inputType: ThemeInputType = .text,
        preview: String? = nil
    ) {
        self.title = title
        _text = text
        self.inputType = inputType
        self.preview = preview ?? text.wrappedValue
    }

    public init(
        _ title: String,
        text: Binding<String>,
        inputType: ThemeInputType = .text,
        preview: (String) -> String?
    ) {
        self.title = title
        _text = text
        self.inputType = inputType
        self.preview = preview(text.wrappedValue)
    }

    public var body: some View {
        ContentPreviewLink(title, content: $text, preview: preview) {
            LongContentEditor(content: $0)
                .themeManualInput(inputType)
                .font(.body)
                .monospaced()
                .navigationTitle(title)
#if os(iOS)
                .navigationBarTitleDisplayMode(.inline)
#endif
        } previewLabel: {
            Text(preview != nil ? $0 : "")
                .foregroundColor(.secondary)
        }
    }
}

#endif
