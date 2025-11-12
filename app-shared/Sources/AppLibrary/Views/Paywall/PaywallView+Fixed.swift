// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonLibrary

import SwiftUI

struct PaywallFixedView: View {

    @Binding
    var isPresented: Bool

    @ObservedObject
    var iapManager: IAPManager

    let requiredFeatures: Set<AppFeature>

    @ObservedObject
    var model: PaywallCoordinator.Model

    @ObservedObject
    var errorHandler: ErrorHandler

    let onComplete: (String, InAppPurchaseResult) -> Void

    let onError: (Error) -> Void

    @FocusState
    private var selectedProduct: AppProduct?

    var body: some View {
        GeometryReader { geo in
            HStack {
                VStack {
                    completeProductsView
                        .if(showsComplete)
                    individualProductsView
                }
                featuresView
                    .padding(.leading, 100)
                    .frame(maxWidth: 0.4 * geo.size.width)

                // TODO: #1511, add bottom links if !os(tvOS)
            }
            .frame(maxHeight: .infinity)
            .themeAnimation(on: iapManager.purchasedProducts, category: .paywall)
#if os(tvOS)
            .themeGradient()
#endif
        }
    }
}

private extension PaywallFixedView {
    var showsComplete: Bool {
        !model.completePurchasable.isEmpty
    }

    var completeProductsView: some View {
        VStack {
            Text(Strings.Views.Paywall.Sections.FullProducts.header)
                .font(.title2)
                .padding(.bottom, 1)
            ForEach(model.completePurchasable, id: \.productIdentifier) { iap in
                PaywallProductView(
                    iapManager: iapManager,
                    style: .paywall(primary: true),
                    product: iap,
                    withIncludedFeatures: false,
                    requiredFeatures: requiredFeatures,
                    purchasingIdentifier: $model.purchasingIdentifier,
                    onComplete: onComplete,
                    onError: onError
                )
                .focused($selectedProduct, equals: AppProduct(rawValue: iap.productIdentifier))
                .frame(maxWidth: .infinity)
                .disabled(iapManager.didPurchase(iap))
            }
            Text(Strings.Views.Paywall.Sections.FullProducts.footer)
                .foregroundStyle(.tertiary)
                .padding(.bottom)
        }
        .themeBlurred(if: !iapManager.isEligibleForComplete)
        .disabled(!iapManager.isEligibleForComplete)
    }

    var individualProductsView: some View {
        VStack {
            if showsComplete {
                Text(Strings.Views.PaywallNew.Sections.Products.header)
                    .font(.headline)
                    .padding(.bottom, 1)
            } else {
                Text(Strings.Global.Actions.purchase)
                    .font(.title2)
                    .padding(.bottom, 1)
            }
            ForEach(model.individualPurchasable, id: \.productIdentifier) { iap in
                PaywallProductView(
                    iapManager: iapManager,
                    style: .paywall(primary: !showsComplete),
                    product: iap,
                    withIncludedFeatures: false,
                    requiredFeatures: requiredFeatures,
                    purchasingIdentifier: $model.purchasingIdentifier,
                    onComplete: onComplete,
                    onError: onError
                )
                .focused($selectedProduct, equals: AppProduct(rawValue: iap.productIdentifier))
                .frame(maxWidth: .infinity)
                .themeBlurred(if: iapManager.didPurchase(iap))
                .disabled(iapManager.didPurchase(iap))
            }
        }
    }

    var featuresView: some View {
        VStack {
            AllFeaturesView(
                marked: Set(selectedProduct?.features ?? []),
                highlighted: requiredFeatures,
                font: .headline
            )
            .frame(maxHeight: .infinity)

            Text(Strings.Views.Paywall.Sections.Products.footer)
                .foregroundStyle(.tertiary)
                .padding(.bottom)
        }
    }
}

// MARK: - Previews

#Preview("WithComplete") {
    let features: Set<AppFeature> = [.appleTV, .dns, .sharing]
    PaywallFixedView(
        isPresented: .constant(true),
        iapManager: .forPreviews,
        requiredFeatures: features,
        model: .forPreviews(features, including: [.complete]),
        errorHandler: .default(),
        onComplete: { _, _ in },
        onError: { _ in }
    )
    .withMockEnvironment()
}

#Preview("WithoutComplete") {
    let features: Set<AppFeature> = [.appleTV, .dns, .sharing]
    PaywallFixedView(
        isPresented: .constant(true),
        iapManager: .forPreviews,
        requiredFeatures: features,
        model: .forPreviews(features, including: []),
        errorHandler: .default(),
        onComplete: { _, _ in },
        onError: { _ in }
    )
    .withMockEnvironment()
}

#Preview("Individual") {
    let features: Set<AppFeature> = [.appleTV]
    PaywallFixedView(
        isPresented: .constant(true),
        iapManager: .forPreviews,
        requiredFeatures: features,
        model: .forPreviews(features, including: []),
        errorHandler: .default(),
        onComplete: { _, _ in },
        onError: { _ in }
    )
    .withMockEnvironment()
}
