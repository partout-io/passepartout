// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import SwiftUI

struct ProfileNameSection: View {

    @Binding
    var name: String

    var body: some View {
        ThemeNameSection(
            name: $name,
            placeholder: Strings.Placeholders.Profile.name,
            footer: Strings.Views.Profile.Sections.Name.footer
        )
        .uiAccessibility(.Profile.name)
    }
}
