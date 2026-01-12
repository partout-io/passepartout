// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import AppAccessibility
import CommonLibrary
import SwiftUI

struct PaywallProductView: View {
    private let iapObservable: IAPObservable

    private let style: PaywallProductViewStyle

    private let storeProduct: ABI.StoreProduct

    private let withIncludedFeatures: Bool

    private let requiredFeatures: Set<ABI.AppFeature>

    @Binding
    private var purchasingIdentifier: String?

    private let onComplete: (String, ABI.StoreResult) -> Void

    private let onError: (Error) -> Void

    @State
    private var isPresentingFeatures = false

    init(
        iapObservable: IAPObservable,
        style: PaywallProductViewStyle,
        storeProduct: ABI.StoreProduct,
        withIncludedFeatures: Bool,
        requiredFeatures: Set<ABI.AppFeature> = [],
        purchasingIdentifier: Binding<String?>,
        onComplete: @escaping (String, ABI.StoreResult) -> Void,
        onError: @escaping (Error) -> Void
    ) {
        self.iapObservable = iapObservable
        self.style = style
        self.storeProduct = storeProduct
        self.withIncludedFeatures = withIncludedFeatures
        self.requiredFeatures = requiredFeatures
        _purchasingIdentifier = purchasingIdentifier
        self.onComplete = onComplete
        self.onError = onError
    }

    var body: some View {
        VStack(alignment: .leading) {
            productView
            if withIncludedFeatures {
                DisclosingFeaturesView(
                    product: storeProduct.product,
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
        isRedundant || isPurchasing || iapObservable.didPurchase(storeProduct.product)
    }

    var isRedundant: Bool {
        guard !storeProduct.product.isDonation else {
            return false
        }
        return storeProduct.product.isRedundant(forRequiredFeatures: requiredFeatures)
    }

    var isPurchasing: Bool {
        purchasingIdentifier != nil
    }

    @ViewBuilder
    var productView: some View {
        if shouldUseStoreKit {
            StoreKitProductView(
                style: style,
                storeProduct: storeProduct,
                purchasingIdentifier: $purchasingIdentifier,
                onComplete: onComplete,
                onError: onError
            )
        } else {
            CustomProductView(
                style: style,
                iapObservable: iapObservable,
                storeProduct: storeProduct,
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
            iapObservable: .forPreviews,
            style: .paywall(primary: true),
            storeProduct: ABI.StoreProduct(
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
