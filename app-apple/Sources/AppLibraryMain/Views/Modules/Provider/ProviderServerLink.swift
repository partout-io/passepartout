// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonLibrary
import SwiftUI

struct ProviderServerLink: View {
    let entity: ProviderEntity?

    var body: some View {
        ProfileLink(
            Strings.Global.Nouns.server,
            value: entity?.localizedDescription,
            route: ProviderModule.Subroute.server
        )
        .uiAccessibility(.Profile.providerServerLink)
    }
}
