// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#if !os(tvOS)

import SwiftUI

public struct ThemeMenuImage: View {

    @EnvironmentObject
    private var theme: Theme

    private let name: Theme.MenuImageName

    public init(_ name: Theme.MenuImageName) {
        self.name = name
    }

    public var body: some View {
        Image(theme.menuImageName(name))
    }
}

#endif
