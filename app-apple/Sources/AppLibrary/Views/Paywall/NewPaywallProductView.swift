// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import AppAccessibility
import CommonLibrary
import SwiftUI

public struct PaywallProductView: View {

    @ObservedObject
    private var iapManager: IAPManager

    private let style: PaywallProductViewStyle

    private let product: InAppProduct

    private let withIncludedFeatures: Bool

    private let requiredFeatures: Set<ABI.AppFeature>

    @Binding
    private var purchasingIdentifier: String?

    private let onComplete: (String, InAppPurchaseResult) -> Void

    private let onError: (Error) -> Void

    @State
    private var isPresentingFeatures = false

    public init(
        iapManager: IAPManager,
        style: PaywallProductViewStyle,
        product: InAppProduct,
        withIncludedFeatures: Bool,
        requiredFeatures: Set<ABI.AppFeature> = [],
        purchasingIdentifier: Binding<String?>,
        onComplete: @escaping (String, InAppPurchaseResult) -> Void,
        onError: @escaping (Error) -> Void
    ) {
        self.iapManager = iapManager
        self.style = style
        self.product = product
        self.withIncludedFeatures = withIncludedFeatures
        self.requiredFeatures = requiredFeatures
        _purchasingIdentifier = purchasingIdentifier
        self.onComplete = onComplete
        self.onError = onError
    }

    public var body: some View {
        VStack(alignment: .leading) {
            productView
            if withIncludedFeatures,
               let product = ABI.AppProduct(rawValue: product.productIdentifier) {
                DisclosingFeaturesView(
                    product: product,
                    requiredFeatures: requiredFeatures,
                    isDisclosing: $isPresentingFeatures
                )
            }
        }
        .themeBlurred(if: shouldDisable)
        .disabled(shouldDisable)
    }
}

private extension PaywallProductView {
    var shouldUseStoreKit: Bool {
#if os(tvOS)
        if case .donation = style {
            return true
        }
#endif
        return false
    }

    var shouldDisable: Bool {
        isRedundant || isPurchasing || iapManager.didPurchase(product)
    }

    var rawProduct: ABI.AppProduct? {
        ABI.AppProduct(rawValue: product.productIdentifier)
    }

    var isRedundant: Bool {
        guard let rawProduct else {
            return false
        }
        guard !rawProduct.isDonation else {
            return false
        }
        return rawProduct.isRedundant(forRequiredFeatures: requiredFeatures)
    }

    var isPurchasing: Bool {
        purchasingIdentifier != nil
    }

    @ViewBuilder
    var productView: some View {
        if shouldUseStoreKit {
            StoreKitProductView(
                style: style,
                product: product,
                purchasingIdentifier: $purchasingIdentifier,
                onComplete: onComplete,
                onError: onError
            )
        } else {
            CustomProductView(
                style: style,
                iapManager: iapManager,
                product: product,
                purchasingIdentifier: $purchasingIdentifier,
                onComplete: onComplete,
                onError: onError
            )
        }
    }
}

#Preview {
    List {
        PaywallProductView(
            iapManager: .forPreviews,
            style: .paywall(primary: true),
            product: InAppProduct(
                productIdentifier: ABI.AppProduct.Features.appleTV.rawValue,
                localizedTitle: "Foo",
                localizedDescription: "Bar",
                localizedPrice: "$10",
                native: nil
            ),
            withIncludedFeatures: true,
            requiredFeatures: [.appleTV],
            purchasingIdentifier: .constant(nil),
            onComplete: { _, _ in },
            onError: { _ in }
        )
    }
    .withMockEnvironment()
}
