// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import AppAccessibility
import CommonLibrary
import SwiftUI

@available(*, deprecated, message: "#1594")
struct LegacyPaywallProductView: View {

    @ObservedObject
    private var iapManager: IAPManager

    private let style: PaywallProductViewStyle

    private let product: ABI.StoreProduct

    private let withIncludedFeatures: Bool

    private let requiredFeatures: Set<ABI.AppFeature>

    @Binding
    private var purchasingIdentifier: String?

    private let onComplete: (String, ABI.StoreResult) -> Void

    private let onError: (Error) -> Void

    @State
    private var isPresentingFeatures = false

    init(
        iapManager: IAPManager,
        style: PaywallProductViewStyle,
        product: ABI.StoreProduct,
        withIncludedFeatures: Bool,
        requiredFeatures: Set<ABI.AppFeature> = [],
        purchasingIdentifier: Binding<String?>,
        onComplete: @escaping (String, ABI.StoreResult) -> Void,
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

    var body: some View {
        VStack(alignment: .leading) {
            productView
            if withIncludedFeatures,
               let product = ABI.AppProduct(rawValue: product.nativeIdentifier) {
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

private extension LegacyPaywallProductView {
    var shouldUseStoreKit: Bool {
#if os(tvOS)
        if case .donation = style {
            return true
        }
#endif
        return false
    }

    var shouldDisable: Bool {
        isRedundant || isPurchasing || iapManager.didPurchase(product.product)
    }

    var rawProduct: ABI.AppProduct? {
        ABI.AppProduct(rawValue: product.nativeIdentifier)
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
                storeProduct: product,
                purchasingIdentifier: $purchasingIdentifier,
                onComplete: onComplete,
                onError: onError
            )
        } else {
            CustomProductView(
                style: style,
                storeProduct: product,
                purchasingIdentifier: $purchasingIdentifier,
                onPurchase: iapManager.purchase,
                onComplete: onComplete,
                onError: onError
            )
        }
    }
}

#Preview {
    List {
        LegacyPaywallProductView(
            iapManager: .forPreviews,
            style: .paywall(primary: true),
            product: ABI.StoreProduct(
                product: ABI.AppProduct.Features.appleTV,
                localizedTitle: "Foo",
                localizedDescription: "Bar",
                localizedPrice: "$10",
                nativeIdentifier: ABI.AppProduct.Features.appleTV.rawValue,
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
