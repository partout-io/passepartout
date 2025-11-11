// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import AppABI
import AppABI_C
import CommonABI
import Observation

@MainActor @Observable
final class IAPObserver: ABIObserver {
    func onUpdate(_ event: ABI.Event) {
    }
}

// MARK: - Actions

//public func enable() async
//public func purchasableProducts(for products: [AppProduct]) async throws -> [InAppProduct]
//public func purchase(_ purchasableProduct: InAppProduct) async throws -> InAppPurchaseResult
//public func restorePurchases() async throws
//public func reloadReceipt() async

//public func observeObjects(withProducts: Bool = true)
//public func fetchLevelIfNeeded() async

// MARK: - State

//public var isLoadingReceipt: Bool
//@Published public var isEnabled = true
//public private(set) var originalPurchase: OriginalPurchase?
//public private(set) var purchasedProducts: Set<AppProduct>
//@Published  public private(set) var eligibleFeatures: Set<AppFeature>
//@Published private var pendingReceiptTask: Task<Void, Never>?

//public var isBeta: Bool
//public func isEligible(for feature: AppFeature) -> Bool
//public func isEligible<C>(for features: C) -> Bool where C: Collection, C.Element == AppFeature
//public var isEligibleForComplete: Bool
//public var isEligibleForFeedback: Bool
//public var isPayingUser: Bool
//public var didPurchaseComplete: Bool
//public func didPurchase(_ purchasable: InAppProduct) -> Bool
//public func didPurchase(_ purchasable: [InAppProduct]) -> Bool
