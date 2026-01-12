// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonLibrary
import SwiftUI

@available(*, deprecated, message: "#1594")
struct LegacyRestorePurchasesButton: View {

    @EnvironmentObject
    private var iapManager: IAPManager

    private let errorHandler: ErrorHandler

    init(errorHandler: ErrorHandler) {
        self.errorHandler = errorHandler
    }

    var body: some View {
        Button(title) {
            Task {
                do {
                    try await iapManager.restorePurchases()
                } catch {
                    errorHandler.handle(error, title: title)
                }
            }
        }
    }
}

private extension LegacyRestorePurchasesButton {
    var title: String {
        Strings.Views.Paywall.Rows.restorePurchases
    }
}
