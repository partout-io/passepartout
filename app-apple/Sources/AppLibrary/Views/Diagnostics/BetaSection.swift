// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import SwiftUI

public struct BetaSection: View {
    public init() {
    }

    public var body: some View {
        Group {
            Text(Strings.Unlocalized.betaBuild)
        }
        .themeSection(header: Strings.Unlocalized.beta)
    }
}

#Preview {
    List {
        BetaSection()
    }
}
