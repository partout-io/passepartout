// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonLibrary
import Foundation

extension PaywallCoordinator {
    @MainActor @Observable
    final class Model {
        var isFetchingProducts = true

        private(set) var suggestedProducts: Set<ABI.AppProduct> = []

        private(set) var completePurchasable: [ABI.StoreProduct] = []

        private(set) var individualPurchasable: [ABI.StoreProduct] = []

        var purchasingIdentifier: String?

        var isPurchasePendingConfirmation = false
    }
}

extension PaywallCoordinator.Model {
    func fetchAvailableProducts(
        for requiredFeatures: Set<ABI.AppFeature>,
        with iapObservable: IAPObservable
    ) async throws {
        guard isFetchingProducts else {
            return
        }
        isFetchingProducts = true
        defer {
            isFetchingProducts = false
        }
        do {
            let rawProducts = iapObservable.suggestedProducts(for: requiredFeatures)
            guard !rawProducts.isEmpty else {
                throw ABI.AppError.emptyProducts
            }
            let rawSortedProducts = rawProducts.sorted {
                $0.productRank < $1.productRank
            }
            let purchasable = try await iapObservable.purchasableProducts(for: rawSortedProducts)
            try setSuggestedProducts(rawProducts, purchasable: purchasable)
        } catch {
            pspLog(.iap, .error, "Unable to load purchasable products: \(error)")
            throw error
        }
    }

    func setSuggestedProducts(
        _ suggestedProducts: Set<ABI.AppProduct>,
        purchasable: [ABI.StoreProduct]
    ) throws {
        let completeProducts = suggestedProducts.filter(\.isComplete)

        var completePurchasable: [ABI.StoreProduct] = []
        var individualPurchasable: [ABI.StoreProduct] = []
        purchasable.forEach {
            if completeProducts.contains($0.product) {
                completePurchasable.append($0)
            } else {
                individualPurchasable.append($0)
            }
        }
        pspLog(.iap, .info, "Individual products: \(individualPurchasable)")
        guard !completePurchasable.isEmpty || !individualPurchasable.isEmpty else {
            throw ABI.AppError.emptyProducts
        }

        self.suggestedProducts = suggestedProducts
        self.completePurchasable = completePurchasable
        self.individualPurchasable = individualPurchasable
    }
}

private extension ABI.AppProduct {
    var productRank: Int {
        switch self {
        case .Essentials.iOS_macOS:
            return .min
        case .Essentials.iOS:
            return 1
        case .Essentials.macOS:
            return 2
        case .Complete.Recurring.yearly:
            return 3
        case .Complete.Recurring.monthly:
            return 4
        default:
            return .max
        }
    }
}

extension PaywallCoordinator.Model {
    @MainActor
    static func forPreviews(
        _ features: Set<ABI.AppFeature>,
        including: Set<IAPManager.SuggestionInclusion>
    ) -> PaywallCoordinator.Model {
        let state = PaywallCoordinator.Model()
        state.isFetchingProducts = false
        let suggested = IAPObservable.forPreviews.suggestedProducts(
            for: features,
            including: including
        )
        try? state.setSuggestedProducts(
            suggested,
            purchasable: suggested.map(\.asFakeStoreProduct)
        )
        return state
    }
}
