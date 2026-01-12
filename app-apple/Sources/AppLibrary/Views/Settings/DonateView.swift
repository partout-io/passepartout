// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonLibrary
import SwiftUI

public struct DonateView<Modifier>: View where Modifier: ViewModifier {
    @Environment(ConfigObservable.self)
    private var configObservable

    private let modifier: Modifier

    public init(modifier: Modifier) {
        self.modifier = modifier
    }

    public var body: some View {
        if configObservable.isUsingObservables {
            NewDonateView(modifier: modifier)
        } else {
            LegacyDonateView(modifier: modifier)
        }
    }
}

public struct NewDonateView<Modifier>: View where Modifier: ViewModifier {
    @Environment(IAPObservable.self)
    private var iapObservable

    @Environment(\.dismiss)
    private var dismiss

    private let modifier: Modifier

    @State
    private var availableProducts: [ABI.StoreProduct] = []

    @State
    private var isFetchingProducts = true

    @State
    private var purchasingIdentifier: String?

    @State
    private var isThankYouPresented = false

    @State
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

private extension NewDonateView {
    var title: String {
        Strings.Views.Donate.title
    }

    var productsRows: some View {
        ForEach(availableProducts, id: \.nativeIdentifier) {
            PaywallProductView(
                iapObservable: iapObservable,
                style: .donation,
                storeProduct: $0,
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

private extension NewDonateView {
    func fetchAvailableProducts() async {
        isFetchingProducts = true
        defer {
            isFetchingProducts = false
        }
        do {
            availableProducts = try await iapObservable.purchasableProducts(for: ABI.AppProduct.Donations.all)
            guard !availableProducts.isEmpty else {
                throw ABI.AppError.emptyProducts
            }
        } catch {
            onError(error, dismissing: false)
        }
    }

    func onComplete(_ productIdentifier: String, result: ABI.StoreResult) {
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

    return NewDonateView(modifier: PreviewModifier())
        .withMockEnvironment()
}
