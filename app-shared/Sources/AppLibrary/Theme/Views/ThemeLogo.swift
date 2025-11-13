// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import SwiftUI

public struct ThemeLogo: View {

    @EnvironmentObject
    private var theme: Theme

    public init() {
    }

    public var body: some View {
        Image(theme.logoImage)
    }
}
