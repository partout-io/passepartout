// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonLibrary
import SwiftUI

struct AppNotWorkingButton: View {

    @EnvironmentObject
    private var apiManager: APIManager

    @EnvironmentObject
    private var iapManager: IAPManager

    @EnvironmentObject
    private var configManager: ConfigManager

    @ObservedObject
    var tunnel: ExtendedTunnel

    @State
    private var isUnableToEmail = false

    var body: some View {
        if let data = configManager.data(for: .appNotWorking) {
            ReportIssueButton(
                title: data.localizedString(forKey: "title"),
                message: data.localizedString(forKey: "message"),
                tunnel: tunnel,
                apiManager: apiManager,
                purchasedProducts: iapManager.purchasedProducts,
                isUnableToEmail: $isUnableToEmail
            )
        }
    }
}

#Preview {
    AppNotWorkingButton(tunnel: .forPreviews)
        .withMockEnvironment()
}
