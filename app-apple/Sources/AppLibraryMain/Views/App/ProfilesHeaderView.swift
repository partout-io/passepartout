// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonLibrary
import SwiftUI

struct ProfilesHeaderView: View {
    @Environment(IAPObservable.self)
    private var iapObservable

    var body: some View {
        HStack {
            Text(Strings.Views.App.Folders.default)
            if iapObservable.isBeta && iapObservable.isLoadingReceipt {
                Spacer()
                Text(Strings.Views.Verification.message)
            }
        }
        .uiAccessibility(.App.profilesHeader)
    }
}
