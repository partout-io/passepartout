// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonLibrary
import SwiftUI

struct ProfilesHeaderView: View {

    @EnvironmentObject
    private var iapManager: IAPManager

    var body: some View {
        HStack {
            Text(Strings.Views.App.Folders.default)
            if iapManager.isBeta && iapManager.isLoadingReceipt {
                Spacer()
                Text(Strings.Views.Verification.message)
            }
        }
        .uiAccessibility(.App.profilesHeader)
    }
}
