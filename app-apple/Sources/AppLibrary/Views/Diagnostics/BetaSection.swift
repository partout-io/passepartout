// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import SwiftUI

public struct BetaSection: View {
    public init() {
    }

    public var body: some View {
        Group {
            Text("This is a beta build")
        }
        .themeSection(header: "Beta")
    }
}

#Preview {
    List {
        BetaSection()
    }
}
