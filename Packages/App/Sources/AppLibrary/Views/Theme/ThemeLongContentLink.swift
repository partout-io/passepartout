// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#if !os(tvOS)

import CommonUtils
import SwiftUI

public struct ThemeLongContentLink: View {
    private let title: String

    @Binding
    private var text: String

    private let preview: String?

    public init(_ title: String, text: Binding<String>, preview: String? = nil) {
        self.title = title
        _text = text
        self.preview = preview ?? text.wrappedValue
    }

    public init(_ title: String, text: Binding<String>, preview: (String) -> String?) {
        self.title = title
        _text = text
        self.preview = preview(text.wrappedValue)
    }

    public var body: some View {
        LongContentLink(title, content: $text, preview: preview) {
            Text(preview != nil ? $0 : "")
                .foregroundColor(.secondary)
        }
    }
}

#endif
