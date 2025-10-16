// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#if !os(tvOS)

import SwiftUI

public struct ThemeTappableText: View {
    private let title: String

    private let action: () -> Void

    public init(title: String, action: @escaping () -> Void) {
        self.title = title
        self.action = action
    }

    var commonView: some View {
        Button(action: action) {
            Text(title)
                .themeTruncating()
        }
    }
}

#endif
