// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import SwiftUI

public struct ContentPreviewLink<Content, Preview>: View where Content: View, Preview: View {
    private let title: String

    @Binding
    private var content: String

    private let preview: String?

    private let contentView: (Binding<String>) -> Content

    private let previewLabel: ((String) -> Preview)?

    public init(
        _ title: String,
        content: Binding<String>,
        preview: String? = nil,
        contentView: @escaping (Binding<String>) -> Content,
        previewLabel: ((String) -> Preview)? = nil
    ) {
        self.title = title
        _content = content
        self.preview = preview
        self.contentView = contentView
        self.previewLabel = previewLabel
    }

    public var body: some View {
        NavigationLink {
            contentView($content)
        } label: {
            HStack {
                Text(title)
                Spacer()
                previewLabel.map {
                    $0(preview ?? content)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
            }
        }
    }
}
