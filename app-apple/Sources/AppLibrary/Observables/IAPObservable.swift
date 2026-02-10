// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonLibrary
import Observation

@MainActor @Observable
public final class IAPObservable {
    private let abi: AppABIIAPProtocol

    public private(set) var isEnabled: Bool
    public private(set) var originalPurchase: ABI.OriginalPurchase?
    public private(set) var eligibleFeatures: Set<ABI.AppFeature>
    public private(set) var isLoadingReceipt: Bool
    private var subscription: Task<Void, Never>?

    public init(abi: AppABIIAPProtocol) {
        self.abi = abi
        isEnabled = abi.isEnabled
        eligibleFeatures = []
        isLoadingReceipt = false
    }
}

// MARK: - Actions

extension IAPObservable {
    public func enable(_ isEnabled: Bool) {
        abi.enable(isEnabled)
    }

    public func purchase(_ storeProduct: ABI.StoreProduct) async throws -> ABI.StoreResult {
        try await abi.purchase(storeProduct)
    }

    public func verify(_ profile: Profile, extra: Set<ABI.AppFeature>?) throws {
        try abi.verify(profile, extra: extra)
    }

    public func reloadReceipt() async {
        await abi.reloadReceipt()
    }

    public func restorePurchases() async throws {
        try await abi.restorePurchases()
    }
}

// MARK: - State

extension IAPObservable {
    public func suggestedProducts(for features: Set<ABI.AppFeature>, including inclusions: Set<IAPManager.SuggestionInclusion> = []) -> Set<ABI.AppProduct> {
        abi.suggestedProducts(for: features, including: inclusions)
    }

    public func purchasableProducts(for products: [ABI.AppProduct]) async throws -> [ABI.StoreProduct] {
        try await abi.purchasableProducts(for: products)
    }

    public var purchasedProducts: Set<ABI.AppProduct> {
        abi.purchasedProducts
    }

    public var isBeta: Bool {
        abi.isBeta
    }

    public func isEligible(for feature: ABI.AppFeature) -> Bool {
        abi.isEligible(for: feature)
    }

    public func isEligible(for features: Set<ABI.AppFeature>) -> Bool {
        abi.isEligible(for: features)
    }

    public var isEligibleForFeedback: Bool {
        abi.isEligibleForFeedback
    }

    public var isEligibleForComplete: Bool {
        abi.isEligibleForComplete
    }

    public var isPayingUser: Bool {
        !purchasedProducts.isEmpty
    }

    public var verificationDelayMinutes: Int {
        abi.verificationDelayMinutes
    }

    public var didPurchaseComplete: Bool {
        purchasedProducts.contains(where: \.isComplete)
    }

    public func didPurchase(_ product: ABI.AppProduct) -> Bool {
        purchasedProducts.contains(product)
    }

    public func didPurchase(_ products: [ABI.AppProduct]) -> Bool {
        products.allSatisfy(didPurchase)
    }

    func onUpdate(_ event: ABI.IAPEvent) {
        switch event {
        case .status(let isEnabled):
            self.isEnabled = isEnabled
        case .eligibleFeatures(let features):
            eligibleFeatures = features
        case .loadReceipt(let isLoading):
            isLoadingReceipt = isLoading
            if !isLoading {
                originalPurchase = abi.originalPurchase
            }
        }
    }
}
