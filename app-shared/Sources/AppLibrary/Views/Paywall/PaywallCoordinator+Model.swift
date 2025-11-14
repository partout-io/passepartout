// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonLibrary
import Foundation
import Partout

extension PaywallCoordinator {

    @MainActor
    final class Model: ObservableObject {

        @Published
        var isFetchingProducts = true

        private(set) var suggestedProducts: Set<AppProduct> = []

        private(set) var completePurchasable: [InAppProduct] = []

        private(set) var individualPurchasable: [InAppProduct] = []

        @Published
        var purchasingIdentifier: String?

        @Published
        var isPurchasePendingConfirmation = false
    }
}

extension PaywallCoordinator.Model {
    func fetchAvailableProducts(
        for requiredFeatures: Set<AppFeature>,
        with iapManager: IAPManager
    ) async throws {
        guard isFetchingProducts else {
            return
        }
        isFetchingProducts = true
        defer {
            isFetchingProducts = false
        }
        do {
            let rawProducts = iapManager.suggestedProducts(for: requiredFeatures)
            guard !rawProducts.isEmpty else {
                throw AppError.emptyProducts
            }
            let rawSortedProducts = rawProducts.sorted {
                $0.productRank < $1.productRank
            }
            let purchasable = try await iapManager.purchasableProducts(for: rawSortedProducts)
            try setSuggestedProducts(rawProducts, purchasable: purchasable)
        } catch {
            pp_log_g(.App.iap, .error, "Unable to load purchasable products: \(error)")
            throw error
        }
    }

    func setSuggestedProducts(
        _ suggestedProducts: Set<AppProduct>,
        purchasable: [InAppProduct]
    ) throws {
        let completeProducts = suggestedProducts.filter(\.isComplete)

        var completePurchasable: [InAppProduct] = []
        var individualPurchasable: [InAppProduct] = []
        purchasable.forEach {
            guard let raw = AppProduct(rawValue: $0.productIdentifier) else {
                return
            }
            if completeProducts.contains(raw) {
                completePurchasable.append($0)
            } else {
                individualPurchasable.append($0)
            }
        }
        pp_log_g(.App.iap, .info, "Individual products: \(individualPurchasable)")
        guard !completePurchasable.isEmpty || !individualPurchasable.isEmpty else {
            throw AppError.emptyProducts
        }

        objectWillChange.send()
        self.suggestedProducts = suggestedProducts
        self.completePurchasable = completePurchasable
        self.individualPurchasable = individualPurchasable
    }
}

private extension AppProduct {
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
        _ features: Set<AppFeature>,
        including: Set<IAPManager.SuggestionInclusion>
    ) -> PaywallCoordinator.Model {
        let state = PaywallCoordinator.Model()
        state.isFetchingProducts = false
        let suggested = IAPManager.forPreviews.suggestedProducts(
            for: features,
            including: including
        )
        try? state.setSuggestedProducts(
            suggested,
            purchasable: suggested.map(\.asFakeIAP)
        )
        return state
    }
}
