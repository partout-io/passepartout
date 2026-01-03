// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#if !os(tvOS)

import SwiftUI

public struct ThemeMenuImage: View {

    @Environment(Theme.self)
    private var theme

    private let name: Theme.MenuImageName

    public init(_ name: Theme.MenuImageName) {
        self.name = name
    }

    public var body: some View {
        Image(theme.menuImageName(name))
    }
}

#endif
