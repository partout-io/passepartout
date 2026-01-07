// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import SwiftUI

struct UUIDText: View {
    let uuid: UUID

    var body: some View {
        ThemeCopiableText(
            Strings.Unlocalized.uuid,
            value: uuid,
            valueView: {
                Text($0.flatString.localizedDescription(style: .quartets))
                    .monospaced()
            }
        )
    }
}
