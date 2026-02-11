// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonLibrary
import SwiftUI

public struct PurchasedView: View {
    @Environment(IAPObservable.self)
    private var iapObservable

    @State
    private var isLoading = true

    @State
    private var products: [ABI.StoreProduct] = []

    @State
    private var errorHandler: ErrorHandler = .default()

    public init() {
    }

    public var body: some View {
        contentView
            .withErrorHandler(errorHandler)
            .themeProgress(if: isLoading)
            .themeAnimation(on: isLoading, category: .diagnostics)
            .onLoad {
                Task {
                    do {
                        products = try await iapObservable
                            .purchasableProducts(for: Array(iapObservable.purchasedProducts))
                            .sorted {
                                $0.localizedTitle < $1.localizedTitle
                            }
                        isLoading = false
                    } catch {
                        errorHandler.handle(error)
                        isLoading = false
                    }
                }
            }
    }
}

private extension PurchasedView {
    var isEmpty: Bool {
        iapObservable.originalPurchase == nil && iapObservable.purchasedProducts.isEmpty && iapObservable.eligibleFeatures.isEmpty
    }

    var allFeatures: [ABI.AppFeature] {
        ABI.AppFeature.allCases.sorted {
            let lRank = $0.rank(with: iapObservable)
            let rRank = $1.rank(with: iapObservable)
            if lRank != rRank {
                return lRank < rRank
            }
            return $0 < $1
        }
    }
}

private extension PurchasedView {
    var contentView: some View {
#if os(macOS)
        Form(content: sectionsGroup)
            .themeForm()
#else
        List(content: sectionsGroup)
#endif
    }

    func sectionsGroup() -> some View {
        Group {
            downloadSection
            productsSection
            featuresSection
            restoreSection
        }
    }

    var downloadSection: some View {
        iapObservable.originalPurchase.map { purchase in
            Group {
                ThemeRow(Strings.Views.Purchased.Rows.buildNumber, value: purchase.buildNumber.description)
                    .scrollableOnTV()
                ThemeRow(Strings.Global.Nouns.date, value: purchase.purchaseDate.description)
                    .scrollableOnTV()
            }
            .themeSection(header: Strings.Views.Purchased.Sections.Download.header)
        }
    }

    var productsSection: some View {
        Group {
            if !products.isEmpty {
                ForEach(products, id: \.nativeIdentifier) {
                    ThemeRow($0.localizedTitle, value: $0.localizedPrice)
                        .scrollableOnTV()
                }
            } else {
                Text(Strings.Views.Purchased.noPurchases)
            }
        }
        .themeSection(header: Strings.Global.Nouns.products)
    }

    var featuresSection: some View {
        Group {
            ForEach(allFeatures, id: \.self) { feature in
                PurchasedFeatureView(text: feature.localizedDescription, isEligible: iapObservable.isEligible(for: feature))
                    .scrollableOnTV()
            }
        }
        .themeSection(header: Strings.Global.Nouns.features)
    }

    var restoreSection: some View {
        RestorePurchasesButton(errorHandler: errorHandler)
            .themeContainerWithSingleEntry(
                header: Strings.Views.Paywall.Sections.Restore.header,
                footer: Strings.Views.Paywall.Sections.Restore.footer,
                isAction: true
            )
    }
}

private struct PurchasedFeatureView: View {
    let text: String

    let isEligible: Bool

    var body: some View {
        HStack {
            Text(text)
            Spacer()
            ThemeImage(isEligible ? .marked : .close)
        }
        .foregroundStyle(isEligible ? .primary : .secondary)
    }
}

// MARK: -

private extension ABI.AppFeature {
    @MainActor
    func rank(with iapObservable: IAPObservable) -> Int {
        iapObservable.isEligible(for: self) ? 0 : 1
    }
}

// MARK: - Previews

#Preview {
    PurchasedView()
        .withMockEnvironment()
}
