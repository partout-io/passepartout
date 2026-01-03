// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import SwiftUI

public struct ThemeCountryText: View {
    private let code: String

    private let title: String?

    public init(_ code: String, title: String? = nil) {
        self.code = code
        self.title = title ?? code.localizedAsRegionCode
    }

    public var body: some View {
        Text(
            [code.asCountryCodeEmoji, title]
                .compactMap { $0 }
                .joined(separator: " ")
        )
    }
}
