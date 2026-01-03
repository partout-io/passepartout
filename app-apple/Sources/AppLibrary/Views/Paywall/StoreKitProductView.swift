// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonLibrary
import StoreKit
import SwiftUI

struct StoreKitProductView: View {
    let style: PaywallProductViewStyle

    let product: InAppProduct

    @Binding
    var purchasingIdentifier: String?

    let onComplete: (String, InAppPurchaseResult) -> Void

    let onError: (Error) -> Void

    var body: some View {
        ProductView(id: product.productIdentifier)
            .withPaywallStyle(style)
            .onInAppPurchaseStart { _ in
                purchasingIdentifier = product.productIdentifier
            }
            .onInAppPurchaseCompletion { skProduct, result in
                do {
                    let skResult = try result.get()
                    onComplete(skProduct.id, skResult.toResult)
                } catch {
                    onError(error)
                }
                purchasingIdentifier = nil
            }
    }
}

@available(iOS 17, macOS 14, tvOS 17, *)
private extension ProductView {

    @ViewBuilder
    func withPaywallStyle(_ paywallStyle: PaywallProductViewStyle) -> some View {
#if os(tvOS)
        switch paywallStyle {
        case .donation:
            productViewStyle(.compact)
                .padding()
        case .paywall:
            productViewStyle(.regular)
                .listRowBackground(Color.clear)
                .listRowInsets(.init())
        }
#else
        productViewStyle(.compact)
#endif
    }
}

private extension Product.PurchaseResult {
    var toResult: InAppPurchaseResult {
        switch self {
        case .success:
            return .done
        case .pending:
            return .pending
        case .userCancelled:
            return .cancelled
        default:
            return .cancelled
        }
    }
}
