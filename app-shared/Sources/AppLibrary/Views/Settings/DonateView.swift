// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonLibrary

import SwiftUI

public struct DonateView<Modifier>: View where Modifier: ViewModifier {

    @EnvironmentObject
    private var iapManager: IAPManager

    @EnvironmentObject
    private var configManager: ConfigManager

    @Environment(\.dismiss)
    private var dismiss

    private let modifier: Modifier

    @State
    private var availableProducts: [InAppProduct] = []

    @State
    private var isFetchingProducts = true

    @State
    private var purchasingIdentifier: String?

    @State
    private var isThankYouPresented = false

    @StateObject
    private var errorHandler: ErrorHandler = .default()

    public init(modifier: Modifier) {
        self.modifier = modifier
    }

    public var body: some View {
        productsRows
            .modifier(modifier)
            .themeProgress(if: isFetchingProducts)
            .disabled(purchasingIdentifier != nil)
            .alert(
                title,
                isPresented: $isThankYouPresented,
                actions: thankYouActions,
                message: thankYouMessage
            )
            .task {
                await fetchAvailableProducts()
            }
            .withErrorHandler(errorHandler)
    }
}

private extension DonateView {
    var title: String {
        Strings.Views.Donate.title
    }

    var productsRows: some View {
        ForEach(availableProducts, id: \.productIdentifier) {
            PaywallProductView(
                iapManager: iapManager,
                style: .donation,
                product: $0,
                withIncludedFeatures: false,
                purchasingIdentifier: $purchasingIdentifier,
                onComplete: onComplete,
                onError: onError
            )
        }
    }

    func thankYouActions() -> some View {
        Button(Strings.Global.Nouns.ok) {
            dismiss()
        }
    }

    func thankYouMessage() -> some View {
        Text(Strings.Views.Donate.Alerts.ThankYou.message)
    }
}

// MARK: -

private extension DonateView {
    func fetchAvailableProducts() async {
        isFetchingProducts = true
        defer {
            isFetchingProducts = false
        }
        do {
            availableProducts = try await iapManager.purchasableProducts(for: AppProduct.Donations.all)
            guard !availableProducts.isEmpty else {
                throw AppError.emptyProducts
            }
        } catch {
            onError(error, dismissing: false)
        }
    }

    func onComplete(_ productIdentifier: String, result: InAppPurchaseResult) {
        switch result {
        case .done:
            isThankYouPresented = true

        case .pending:
            dismiss()

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
        errorHandler.handle(error, title: title) {
            if dismissing {
                dismiss()
            }
        }
    }
}

// MARK: - Previews

#Preview {
    struct PreviewModifier: ViewModifier {
        func body(content: Content) -> some View {
            List {
                content
            }
        }
    }

    return DonateView(modifier: PreviewModifier())
        .withMockEnvironment()
}
