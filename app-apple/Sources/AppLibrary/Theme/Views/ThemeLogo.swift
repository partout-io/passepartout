// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import SwiftUI

public struct ThemeLogo: View {

    @Environment(Theme.self)
    private var theme

    public init() {
    }

    public var body: some View {
        Image(theme.logoImage)
    }
}
