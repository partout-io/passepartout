//
//  PaywallView.swift
//  Passepartout
//
//  Created by Davide De Rosa on 9/10/24.
//  Copyright (c) 2024 Davide De Rosa. All rights reserved.
//
//  https://github.com/passepartoutvpn
//
//  This file is part of Passepartout.
//
//  Passepartout is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  Passepartout is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with Passepartout.  If not, see <http://www.gnu.org/licenses/>.
//

import CommonLibrary
import CommonUtils
import StoreKit
import SwiftUI

struct PaywallView: View {
    enum ProductStyle {
        case oneTime

        case recurring
    }

    @EnvironmentObject
    private var iapManager: IAPManager

    @Binding
    var isPresented: Bool

    let feature: AppFeature

    let suggestedProduct: AppProduct?

    @State
    private var isFetchingProducts = true

    @State
    private var oneTimeProduct: InAppProduct?

    @State
    private var recurringProducts: [InAppProduct] = []

    @State
    private var isPendingPresented = false

    @StateObject
    private var errorHandler: ErrorHandler = .default()

    var body: some View {
        Form {
            if isFetchingProducts {
                ProgressView()
                    .id(UUID())
            } else {
                productsView
                subscriptionFeaturesView
                restoreView
            }
        }
        .themeForm()
        .toolbar(content: toolbarContent)
        .alert(
            Strings.Global.purchase,
            isPresented: $isPendingPresented,
            actions: pendingActions,
            message: pendingMessage
        )
        .task(id: feature) {
            await fetchAvailableProducts()
        }
        .withErrorHandler(errorHandler)
    }
}

private extension PaywallView {
    var title: String {
        Strings.Global.purchase
    }

    var subscriptionFeatures: [AppFeature] {
        AppFeature.allCases.sorted {
            $0.localizedDescription < $1.localizedDescription
        }
    }

    @ViewBuilder
    var productsView: some View {
        oneTimeProduct.map {
            productView(.oneTime, for: $0)
                .themeSection(header: Strings.Paywall.Sections.OneTime.header)
        }
        ForEach(recurringProducts, id: \.productIdentifier) {
            productView(.recurring, for: $0)
        }
        .themeSection(header: Strings.Paywall.Sections.Recurring.header)
    }

#if os(iOS) || os(tvOS)
    var subscriptionFeaturesView: some View {
        ForEach(subscriptionFeatures, id: \.id) { feature in
            Text(feature.localizedDescription)
        }
        .themeSection(header: Strings.Paywall.Sections.Features.header)
    }
#else
    var subscriptionFeaturesView: some View {
        Table(subscriptionFeatures) {
            TableColumn(Strings.Paywall.Sections.Features.header, value: \.localizedDescription)
        }
    }
#endif

    @ViewBuilder
    func productView(_ style: ProductStyle, for product: InAppProduct) -> some View {
        if #available(iOS 17, macOS 14, *) {
            StoreKitProductView(
                style: style,
                product: product,
                onComplete: onComplete,
                onError: onError
            )
        } else {
            CustomProductView(
                style: style,
                iapManager: iapManager,
                product: product,
                onComplete: onComplete,
                onError: onError
            )
        }
    }

    var restoreView: some View {
        RestorePurchasesButton()
            .themeSectionWithSingleRow(
                header: Strings.Paywall.Sections.Restore.header,
                footer: Strings.Paywall.Sections.Restore.footer,
                above: true
            )
    }
}

private extension PaywallView {

    @ToolbarContentBuilder
    func toolbarContent() -> some ToolbarContent {
        ToolbarItem(placement: .cancellationAction) {
            Button {
                isPresented = false
            } label: {
                ThemeCloseLabel()
            }
        }
    }

    func pendingActions() -> some View {
        Button(Strings.Global.ok) {
            isPresented = false
        }
    }

    func pendingMessage() -> some View {
        Text(Strings.Paywall.Alerts.Pending.message)
    }
}

// MARK: -

private extension PaywallView {
    func fetchAvailableProducts() async {
        isFetchingProducts = true

        var list: [AppProduct] = []
        if let suggestedProduct {
            list.append(suggestedProduct)
        }
        list.append(.Full.Recurring.yearly)
        list.append(.Full.Recurring.monthly)

        let availableProducts = await iapManager.purchasableProducts(for: list)
        oneTimeProduct = availableProducts.first {
            guard let suggestedProduct else {
                return false
            }
            return $0.productIdentifier.hasSuffix(suggestedProduct.rawValue)
        }
        recurringProducts = availableProducts.filter {
            $0.productIdentifier != oneTimeProduct?.productIdentifier
        }

        isFetchingProducts = false
    }

    func onComplete(_ productIdentifier: String, result: InAppPurchaseResult) {
        switch result {
        case .done:
            isPresented = false

        case .pending:
            isPendingPresented = true

        case .cancelled:
            break

        case .notFound:
            fatalError("Product not found: \(productIdentifier)")
        }
    }

    func onError(_ error: Error) {
        errorHandler.handle(error, title: Strings.Global.purchase)
    }
}

// MARK: - Previews

#Preview {
    PaywallView(
        isPresented: .constant(true),
        feature: .appleTV,
        suggestedProduct: .Features.appleTV
    )
    .withMockEnvironment()
}
