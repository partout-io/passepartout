// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonLibrary
import SwiftUI

public struct ExternalLink: View {
    private let title: String

    private let url: URL

    private let withIcon: Bool

    public init(_ title: String, url: URL, withIcon: Bool? = nil) {
        self.title = title
        self.url = url
#if os(macOS)
        self.withIcon = withIcon ?? true
#else
        self.withIcon = withIcon ?? false
#endif
    }

    public var body: some View {
        Link(destination: url) {
            HStack {
                Text(title)
                    .themeMultiLine(true)
                Spacer()
                if withIcon {
                    ThemeImage(.externalLink)
                }
            }
        }
#if os(macOS)
        .foregroundStyle(.primary)
#endif
    }
}

#Preview {
    ExternalLink(
        "A very long line and more more and more",
        url: URL(string: "https://")!,
        withIcon: true
    )
    .withMockEnvironment()
}
