// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import SwiftUI

public struct ThemeImage: View {

    @Environment(Theme.self)
    private var theme

    private let name: Theme.ImageName

    public init(_ name: Theme.ImageName) {
        self.name = name
    }

    public var body: some View {
        Image(systemName: theme.systemImageName(name))
    }
}
