// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonLibrary
import SwiftUI

struct ProviderNameRow: View {

    @EnvironmentObject
    private var apiManager: APIManager

    let id: ProviderID

    var body: some View {
        apiManager.provider(withId: id)
            .map {
                ThemeRow(Strings.Global.Nouns.name, value: $0.description)
            }
    }
}
