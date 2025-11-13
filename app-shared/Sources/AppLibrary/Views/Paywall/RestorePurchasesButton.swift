// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonLibrary
import SwiftUI

public struct RestorePurchasesButton: View {

    @EnvironmentObject
    private var iapManager: IAPManager

    @ObservedObject
    private var errorHandler: ErrorHandler

    public init(errorHandler: ErrorHandler) {
        self.errorHandler = errorHandler
    }

    public var body: some View {
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

private extension RestorePurchasesButton {
    var title: String {
        Strings.Views.Paywall.Rows.restorePurchases
    }
}
