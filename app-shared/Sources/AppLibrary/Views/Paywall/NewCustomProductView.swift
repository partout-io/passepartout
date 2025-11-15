// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonLibrary

import StoreKit
import SwiftUI

struct CustomProductView: View {

    @Environment(\.isEnabled)
    private var isEnabled

    let style: PaywallProductViewStyle

    @ObservedObject
    var iapManager: IAPManager

    let product: InAppProduct

    @Binding
    var purchasingIdentifier: String?

    let onComplete: (String, InAppPurchaseResult) -> Void

    let onError: (Error) -> Void

    var body: some View {
        contentView
    }
}

private extension CustomProductView {
    var contentView: some View {
#if os(tvOS)
        Button(action: purchase) {
            VStack(alignment: .leading) {
                Text(verbatim: product.localizedTitle)
                    .themeTrailingValue(product.localizedPrice)
                    .font(withDescription ? .headline : .footnote)

                if withDescription {
                    Text(verbatim: product.localizedDescription)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
        }
#else
        HStack {
            VStack(alignment: .leading) {
                Text(verbatim: product.localizedTitle)
                    .font(isPrimary ? .title2 : withFooter ? .headline : nil)
                    .fontWeight(isPrimary ? .bold : nil)

                if withDescription {
                    Text(verbatim: product.localizedDescription)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            Button(action: purchase) {
                Text(product.localizedPrice)
                    .font(.headline)
                    .fontWeight(.bold)
                    .padding(.horizontal, 15)
                    .padding(.vertical, 5)
                    .background(.quinary)
                    .clipShape(.capsule)
                    .foregroundStyle(isEnabled ? Color.accentColor : .gray)
                    .cursor(.hand)
            }
            .buttonStyle(.borderless)
        }
        .padding(withPadding ? 10 : .zero)
#endif
    }
}

private extension CustomProductView {
    var isPurchasing: Bool {
        purchasingIdentifier != nil
    }

    var isPrimary: Bool {
        switch style {
        case .donation:
            false
        case .paywall(let primary):
            primary
        }
    }

    var withDescription: Bool {
        switch style {
        case .donation:
            false
        case .paywall(let primary):
            primary
        }
    }

    var withFooter: Bool {
        switch style {
        case .donation:
            false
        case .paywall(let primary):
#if os(tvOS)
            primary
#else
            true // disclosing features
#endif
        }
    }

    var withPadding: Bool {
        switch style {
        case .donation:
            true
        case .paywall:
            false
        }
    }
}

private extension CustomProductView {
    func purchase() {
        purchasingIdentifier = product.productIdentifier
        Task {
            defer {
                purchasingIdentifier = nil
            }
            do {
                let result = try await iapManager.purchase(product)
                onComplete(product.productIdentifier, result)
            } catch {
                onError(error)
            }
        }
    }
}

#Preview {
    List {
        CustomProductView(
            style: .paywall(primary: true),
            iapManager: .forPreviews,
            product: ABI.AppProduct.Complete.OneTime.lifetime.asFakeIAP,
            purchasingIdentifier: .constant(nil),
            onComplete: { _, _ in },
            onError: { _ in }
        )
    }
}
