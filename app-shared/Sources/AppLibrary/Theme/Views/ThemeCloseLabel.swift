// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import SwiftUI

public struct ThemeCloseLabel: View {
    private let title: String

    public init(title: String? = nil) {
        self.title = title ?? Strings.Global.Actions.cancel
    }

    public var body: some View {
#if os(iOS) || os(tvOS)
        ThemeImage(.close)
#else
        Text(title)
#endif
    }
}
