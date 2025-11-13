// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonLibrary
import SwiftUI

struct PaywallCoordinator: View {

    @EnvironmentObject
    private var iapManager: IAPManager

    @Binding
    var isPresented: Bool

    let requiredFeatures: Set<AppFeature>

    @StateObject
    private var model = Model()

    @StateObject
    private var errorHandler: ErrorHandler = .default()

    var body: some View {
        contentView
            .themeProgress(if: model.isFetchingProducts)
            .disabled(model.purchasingIdentifier != nil)
            .alert(
                Strings.Global.Actions.purchase,
                isPresented: $model.isPurchasePendingConfirmation,
                actions: pendingActions,
                message: pendingMessage
            )
            .task(id: requiredFeatures) {
                do {
                    try await model.fetchAvailableProducts(
                        for: requiredFeatures,
                        with: iapManager
                    )
                } catch {
                    onError(error, dismissing: true)
                }
            }
            .withErrorHandler(errorHandler)
    }
}

private extension PaywallCoordinator {
    var contentView: some View {
        PaywallView(
            isPresented: $isPresented,
            iapManager: iapManager,
            requiredFeatures: requiredFeatures,
            model: model,
            errorHandler: errorHandler,
            onComplete: onComplete,
            onError: onError
        )
        .themeNavigationStack(closable: isPaywallClosable)
    }

    var isPaywallClosable: Bool {
#if os(tvOS)
        false
#else
        true
#endif
    }

    func pendingActions() -> some View {
        Button(Strings.Global.Nouns.ok) {
            isPresented = false
        }
    }

    func pendingMessage() -> some View {
        Text(Strings.Views.Paywall.Alerts.Pending.message)
    }
}

private extension PaywallCoordinator {
    var didPurchaseRequired: Bool {
        iapManager.isEligible(for: requiredFeatures)
    }

    func onComplete(_ productIdentifier: String, result: InAppPurchaseResult) {
        switch result {
        case .done:
            Task {
                await iapManager.reloadReceipt()
                if didPurchaseRequired {
                    isPresented = false
                }
            }
        case .pending:
            model.isPurchasePendingConfirmation = true
        case .cancelled:
            break
        case .notFound:
            fatalError("Product not found: \(productIdentifier)")
        }
    }

    func onError(_ error: Error) {
        onError(error, dismissing: false)
    }

    func onError(_ error: Error, dismissing: Bool) {
        errorHandler.handle(error, title: Strings.Global.Actions.purchase) {
            if dismissing {
                isPresented = false
            }
        }
    }
}

// MARK: - Previews

#Preview {
    PaywallCoordinator(
        isPresented: .constant(true),
        requiredFeatures: [.appleTV, .dns, .sharing]
    )
    .withMockEnvironment()
}
