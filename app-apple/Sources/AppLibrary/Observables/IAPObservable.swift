// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonLibrary
import Observation

@MainActor @Observable
public final class IAPObservable {
    private let abi: AppABIIAPProtocol

    public private(set) var isEnabled: Bool
    public private(set) var isLoadingReceipt: Bool
    public private(set) var isBeta: Bool
    public private(set) var originalPurchase: ABI.OriginalPurchase?
    public private(set) var purchasedProducts: Set<ABI.AppProduct>
    public private(set) var eligibleFeatures: Set<ABI.AppFeature>
    private var subscription: Task<Void, Never>?

    public init(abi: AppABIIAPProtocol) {
        self.abi = abi
        isEnabled = true
        isLoadingReceipt = true
        isBeta = false
        purchasedProducts = []
        eligibleFeatures = []
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
    public func suggestedProducts(
        for features: Set<ABI.AppFeature>,
        hints: Set<ABI.StoreProductHint>? = nil
    ) -> Set<ABI.AppProduct> {
        abi.suggestedProducts(for: features, hints: hints)
    }

    public func purchasableProducts(for products: [ABI.AppProduct]) async throws -> [ABI.StoreProduct] {
        try await abi.purchasableProducts(for: products)
    }

    public var verificationDelayMinutes: Int {
        abi.verificationDelayMinutes
    }

    public func isEligible(for feature: ABI.AppFeature) -> Bool {
        eligibleFeatures.contains(feature)
    }

    public func isEligible<C>(for features: C) -> Bool where C: Collection, C.Element == ABI.AppFeature {
        features.isEmpty || features.allSatisfy(eligibleFeatures.contains)
    }

    public var isEligibleForComplete: Bool {
        let rawProducts = purchasedProducts.compactMap {
            ABI.AppProduct(rawValue: $0.rawValue)
        }

        //
        // Allow purchasing complete products only if:
        //
        // - never bought complete products ('Forever', subscriptions)
        // - never bought 'Essentials' products (suggest individual features instead)
        // - never bought 'Apple TV' product (suggest 'Essentials' instead)
        //
        return !rawProducts.contains {
            $0.isComplete || $0.isEssentials || $0 == .Features.appleTV
        }
    }

    public var isEligibleForFeedback: Bool {
#if os(tvOS)
        false
#else
        isBeta || isPayingUser
#endif
    }

    public var isPayingUser: Bool {
        !purchasedProducts.isEmpty
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
        case .loadReceipt(let isLoading):
            isLoadingReceipt = isLoading
        case .newReceipt(let purchase, let products, let isBeta):
            originalPurchase = purchase
            purchasedProducts = products
            self.isBeta = isBeta
        case .eligibleFeatures(let features):
            eligibleFeatures = features
        }
    }
}
