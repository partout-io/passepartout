// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonLibrary
import StoreKit
import SwiftUI

struct PaywallScrollableView: View {
    @Environment(\.appConfiguration)
    private var appConfiguration

    @Binding
    var isPresented: Bool

    let iapObservable: IAPObservable

    let requiredFeatures: Set<ABI.AppFeature>

    let model: PaywallCoordinator.Model

    let errorHandler: ErrorHandler

    let onComplete: (String, ABI.StoreResult) -> Void

    let onError: (Error) -> Void

    var body: some View {
        Form {
            completeProductsView
                .if(!model.completePurchasable.isEmpty)
            individualProductsView
                .if(!model.individualPurchasable.isEmpty)
            restoreView
            linksView
        }
        .themeForm()
    }
}

private extension PaywallScrollableView {
    var completeProductsView: some View {
        Group {
            ForEach(model.completePurchasable, id: \.nativeIdentifier) {
                PaywallProductView(
                    iapObservable: iapObservable,
                    style: .paywall(primary: true),
                    storeProduct: $0,
                    withIncludedFeatures: false,
                    requiredFeatures: requiredFeatures,
                    purchasingIdentifier: model.binding(\.purchasingIdentifier),
                    onComplete: onComplete,
                    onError: onError
                )
            }
            AllFeaturesView(
                marked: [],
                highlighted: requiredFeatures
            )
        }
        .themeSection(
            header: Strings.Views.Paywall.Sections.FullProducts.header,
            footer: [
                Strings.Views.Paywall.Sections.FullProducts.footer,
                Strings.Views.Paywall.Sections.Products.footer
            ].joined(separator: " ")
        )
        .themeBlurred(if: !iapObservable.isEligibleForComplete)
        .disabled(!iapObservable.isEligibleForComplete)
    }

    var individualProductsView: some View {
        ForEach(model.individualPurchasable, id: \.nativeIdentifier) {
            PaywallProductView(
                iapObservable: iapObservable,
                style: .paywall(primary: false),
                storeProduct: $0,
                withIncludedFeatures: true,
                requiredFeatures: requiredFeatures,
                purchasingIdentifier: model.binding(\.purchasingIdentifier),
                onComplete: onComplete,
                onError: onError
            )
        }
        .themeSection(
            header: Strings.Views.PaywallNew.Sections.Products.header,
            footer: Strings.Views.Paywall.Sections.Products.footer
        )
    }

    var linksView: some View {
        Section {
            Link(Strings.Unlocalized.eula, destination: appConfiguration.constants.websites.eula)
            Link(Strings.Views.Settings.Links.Rows.privacyPolicy, destination: appConfiguration.constants.websites.privacyPolicy)
        }
    }

    var restoreView: some View {
        RestorePurchasesButton(errorHandler: errorHandler)
            .themeContainerWithSingleEntry(
                header: Strings.Views.Paywall.Sections.Restore.header,
                footer: Strings.Views.Paywall.Sections.Restore.footer,
                isAction: true
            )
    }
}

// MARK: - Previews

#Preview {
    let features: Set<ABI.AppFeature> = [.appleTV, .dns, .sharing]
    PaywallScrollableView(
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
