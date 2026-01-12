// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonLibrary
import StoreKit
import SwiftUI

struct CustomProductView: View {
    @Environment(\.isEnabled)
    private var isEnabled

    let style: PaywallProductViewStyle

    let storeProduct: ABI.StoreProduct

    @Binding
    var purchasingIdentifier: String?

    let onPurchase: (ABI.StoreProduct) async throws -> ABI.StoreResult

    let onComplete: (String, ABI.StoreResult) -> Void

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
                Text(verbatim: storeProduct.localizedTitle)
                    .themeTrailingValue(storeProduct.localizedPrice)
                    .font(withDescription ? .headline : .footnote)

                if withDescription {
                    Text(verbatim: storeProduct.localizedDescription)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
        }
#else
        HStack {
            VStack(alignment: .leading) {
                Text(verbatim: storeProduct.localizedTitle)
                    .font(isPrimary ? .title2 : withFooter ? .headline : nil)
                    .fontWeight(isPrimary ? .bold : nil)

                if withDescription {
                    Text(verbatim: storeProduct.localizedDescription)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            Button(action: purchase) {
                Text(storeProduct.localizedPrice)
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
        purchasingIdentifier = storeProduct.nativeIdentifier
        Task {
            defer {
                purchasingIdentifier = nil
            }
            do {
                let result = try await onPurchase(storeProduct)
                onComplete(storeProduct.nativeIdentifier, result)
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
            storeProduct: ABI.AppProduct.Complete.OneTime.lifetime.asFakeStoreProduct,
            purchasingIdentifier: .constant(nil),
            onPurchase: { _ in .done },
            onComplete: { _, _ in },
            onError: { _ in }
        )
    }
}
