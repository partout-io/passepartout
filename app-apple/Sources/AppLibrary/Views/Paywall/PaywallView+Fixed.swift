// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonLibrary
import SwiftUI

struct PaywallFixedView: View {
    @Binding
    var isPresented: Bool

    let iapObservable: IAPObservable

    let requiredFeatures: Set<ABI.AppFeature>

    let model: PaywallCoordinator.Model

    let errorHandler: ErrorHandler

    let onComplete: (String, ABI.StoreResult) -> Void

    let onError: (Error) -> Void

    @FocusState
    private var selectedProduct: ABI.AppProduct?

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
            .themeAnimation(on: iapObservable.purchasedProducts, category: .paywall)
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
            ForEach(model.completePurchasable, id: \.nativeIdentifier) { iap in
                PaywallProductView(
                    iapObservable: iapObservable,
                    style: .paywall(primary: true),
                    storeProduct: iap,
                    withIncludedFeatures: false,
                    requiredFeatures: requiredFeatures,
                    purchasingIdentifier: model.binding(\.purchasingIdentifier),
                    onComplete: onComplete,
                    onError: onError
                )
                .focused($selectedProduct, equals: iap.product)
                .frame(maxWidth: .infinity)
                .disabled(iapObservable.didPurchase(iap.product))
            }
            Text(Strings.Views.Paywall.Sections.FullProducts.footer)
                .foregroundStyle(.tertiary)
                .padding(.bottom)
        }
        .themeBlurred(if: !iapObservable.isEligibleForComplete)
        .disabled(!iapObservable.isEligibleForComplete)
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
            ForEach(model.individualPurchasable, id: \.nativeIdentifier) { iap in
                PaywallProductView(
                    iapObservable: iapObservable,
                    style: .paywall(primary: !showsComplete),
                    storeProduct: iap,
                    withIncludedFeatures: false,
                    requiredFeatures: requiredFeatures,
                    purchasingIdentifier: model.binding(\.purchasingIdentifier),
                    onComplete: onComplete,
                    onError: onError
                )
                .focused($selectedProduct, equals: iap.product)
                .frame(maxWidth: .infinity)
                .themeBlurred(if: iapObservable.didPurchase(iap.product))
                .disabled(iapObservable.didPurchase(iap.product))
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
    let features: Set<ABI.AppFeature> = [.appleTV, .dns, .sharing]
    PaywallFixedView(
        isPresented: .constant(true),
        iapObservable: .forPreviews,
        requiredFeatures: features,
        model: .forPreviews(features, hints: [.complete]),
        errorHandler: .default(),
        onComplete: { _, _ in },
        onError: { _ in }
    )
    .withMockEnvironment()
}

#Preview("WithoutComplete") {
    let features: Set<ABI.AppFeature> = [.appleTV, .dns, .sharing]
    PaywallFixedView(
        isPresented: .constant(true),
        iapObservable: .forPreviews,
        requiredFeatures: features,
        model: .forPreviews(features, hints: []),
        errorHandler: .default(),
        onComplete: { _, _ in },
        onError: { _ in }
    )
    .withMockEnvironment()
}

#Preview("Individual") {
    let features: Set<ABI.AppFeature> = [.appleTV]
    PaywallFixedView(
        isPresented: .constant(true),
        iapObservable: .forPreviews,
        requiredFeatures: features,
        model: .forPreviews(features, hints: []),
        errorHandler: .default(),
        onComplete: { _, _ in },
        onError: { _ in }
    )
    .withMockEnvironment()
}
