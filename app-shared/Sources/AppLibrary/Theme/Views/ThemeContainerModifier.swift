// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import SwiftUI

struct ThemeContainerModifier: ViewModifier {
    let header: String?

    let footer: String?
}

struct ThemeContainerEntryModifier: ViewModifier {
    let header: String?

    let subtitle: String?

    let isAction: Bool
}
