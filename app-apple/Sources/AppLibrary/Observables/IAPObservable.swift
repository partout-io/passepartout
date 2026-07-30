// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonLibrary
import Observation

@MainActor @Observable
public final class IAPObservable {
    private let iapManager: IAPManager
    private let supportsIAP: Bool

    public private(set) var isEnabled: Bool
    public private(set) var isLoadingReceipt: Bool
    public private(set) var isBeta: Bool
    public private(set) var originalPurchase: ABI.OriginalPurchase?
    public private(set) var purchasedProducts: Set<ABI.AppProduct>
    public private(set) var eligibleFeatures: Set<ABI.AppFeature>
    public private(set) var isEligibleForComplete: Bool
    public private(set) var isEligibleForFeedback: Bool
    private var subscription: Task<Void, Never>?

    public init(iapManager: IAPManager, supportsIAP: Bool) {
        self.iapManager = iapManager
        self.supportsIAP = supportsIAP
        isEnabled = true
        isLoadingReceipt = true
        isBeta = false
        purchasedProducts = []
        eligibleFeatures = []
        isEligibleForComplete = false
        isEligibleForFeedback = false
    }
}

// MARK: - Actions

extension IAPObservable {
    public func enable(_ isEnabled: Bool) {
        iapManager.isEnabled = supportsIAP && isEnabled
    }

    public func purchase(_ storeProduct: ABI.StoreProduct) async throws -> ABI.StoreResult {
        try await iapManager.purchase(storeProduct)
    }

    public func verify(_ profile: Profile, extra: Set<ABI.AppFeature>?) throws {
        try iapManager.verify(profile, extra: extra)
    }

    public func reloadReceipt() async {
        await iapManager.reloadReceipt()
    }

    public func restorePurchases() async throws {
        try await iapManager.restorePurchases()
    }
}

// MARK: - State

extension IAPObservable {
    public func suggestedProducts(
        for features: Set<ABI.AppFeature>,
        hints: Set<ABI.StoreProductHint>? = nil
    ) -> Set<ABI.AppProduct> {
        iapManager.suggestedProducts(for: features, hints: hints)
    }

    public func purchasableProducts(for products: [ABI.AppProduct]) async throws -> [ABI.StoreProduct] {
        try await iapManager.fetchPurchasableProducts(for: products)
    }

    public var verificationDelayMinutes: Int {
        iapManager.verificationDelayMinutes
    }

    public func isEligible(for feature: ABI.AppFeature) -> Bool {
        eligibleFeatures.contains(feature)
    }

    public func isEligible<C>(for features: C) -> Bool where C: Collection, C.Element == ABI.AppFeature {
        features.isEmpty || features.allSatisfy(eligibleFeatures.contains)
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
        case .status(let payload):
            isEnabled = payload.isEnabled
        case .loadReceipt(let payload):
            isLoadingReceipt = payload.isLoading
        case .newReceipt(let payload):
            originalPurchase = payload.originalPurchase
            purchasedProducts = payload.products
            isBeta = payload.isBeta
        case .eligibleFeatures(let payload):
            eligibleFeatures = Set(payload.features)
            isEligibleForComplete = payload.forComplete
            isEligibleForFeedback = payload.forFeedback
        }
    }
}
