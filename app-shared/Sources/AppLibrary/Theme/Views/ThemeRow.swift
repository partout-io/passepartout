// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import SwiftUI

public struct ThemeRow: View {
    private let title: String

    private let value: String?

    public init(_ title: String, value: String? = nil) {
        self.title = title
        self.value = value
    }

    public var body: some View {
        Text(title)
            .themeTrailingValue(value)
    }
}
