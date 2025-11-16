// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import Combine
import Foundation
import Partout

@MainActor
public final class IAPManager: ObservableObject {
    private let customUserLevel: ABI.AppUserLevel?

    private let inAppHelper: any AppProductHelper

    private let receiptReader: AppReceiptReader

    private let betaChecker: BetaChecker

    private let unrestrictedFeatures: Set<ABI.AppFeature>

    private let timeoutInterval: TimeInterval

    private let productsAtBuild: BuildProducts<ABI.AppProduct>?

    // FIXME: #1594, AppContext requires Published
    @Published
    public var isEnabled = true {
//        willSet {
//            objectWillChange.send()
//        }
        didSet {
            pendingReceiptTask?.cancel()
        }
    }

    private(set) var userLevel: ABI.AppUserLevel

    public private(set) var originalPurchase: OriginalPurchase?

    public private(set) var purchasedProducts: Set<ABI.AppProduct>

    // FIXME: #1594, AppContext requires Published
    @Published
    public private(set) var eligibleFeatures: Set<ABI.AppFeature> {
//        willSet {
//            objectWillChange.send()
//        }
    }

    private var pendingReceiptTask: Task<Void, Never>? {
        willSet {
            objectWillChange.send()
        }
    }

    private var subscriptions: Set<AnyCancellable>

    public init(
        customUserLevel: ABI.AppUserLevel? = nil,
        inAppHelper: any AppProductHelper,
        receiptReader: AppReceiptReader,
        betaChecker: BetaChecker,
        unrestrictedFeatures: Set<ABI.AppFeature> = [],
        timeoutInterval: TimeInterval,
        productsAtBuild: BuildProducts<ABI.AppProduct>? = nil
    ) {
        self.customUserLevel = customUserLevel
        self.inAppHelper = inAppHelper
        self.receiptReader = receiptReader
        self.betaChecker = betaChecker
        self.unrestrictedFeatures = unrestrictedFeatures
        self.timeoutInterval = timeoutInterval
        self.productsAtBuild = productsAtBuild
        userLevel = .undefined
        purchasedProducts = []
        eligibleFeatures = []
        subscriptions = []
    }
}

// MARK: - Actions

extension IAPManager {
    public var isLoadingReceipt: Bool {
        pendingReceiptTask != nil
    }

    public func enable() async {
        guard !isEnabled else {
            return
        }
        isEnabled = true
        await reloadReceipt()
    }

    public func purchasableProducts(for products: [ABI.AppProduct]) async throws -> [InAppProduct] {
        guard isEnabled else {
            return []
        }
        do {
            let inAppProducts = try await inAppHelper.fetchProducts(timeout: timeoutInterval)
            return products.compactMap {
                inAppProducts[$0]
            }
        } catch is TaskTimeoutError {
            throw ABI.AppError.timeout
        } catch {
            pp_log_g(.App.iap, .error, "Unable to fetch in-app products: \(error)")
            throw error
        }
    }

    public func purchase(_ purchasableProduct: InAppProduct) async throws -> InAppPurchaseResult {
        guard isEnabled else {
            return .cancelled
        }
        let result = try await inAppHelper.purchase(purchasableProduct)
        if result == .done {
            await receiptReader.addPurchase(with: purchasableProduct.productIdentifier)
            await reloadReceipt()
        }
        return result
    }

    public func restorePurchases() async throws {
        guard isEnabled else {
            return
        }
        try await inAppHelper.restorePurchases()
        await reloadReceipt()
    }

    public func reloadReceipt() async {
        guard isEnabled else {
            purchasedProducts = []
            eligibleFeatures = []
            return
        }
        if let pendingReceiptTask {
            await pendingReceiptTask.value
        }
        pendingReceiptTask = Task {
            await fetchLevelIfNeeded()
            await asyncReloadReceipt()
        }
        await pendingReceiptTask?.value
        pendingReceiptTask = nil
    }
}

// MARK: - Eligibility

extension IAPManager {
    public var isBeta: Bool {
        userLevel.isBeta
    }

    public func isEligible(for feature: ABI.AppFeature) -> Bool {
        eligibleFeatures.contains(feature)
    }

    public func isEligible<C>(for features: C) -> Bool where C: Collection, C.Element == ABI.AppFeature {
        if features.isEmpty {
            return true
        }
        return features.allSatisfy(eligibleFeatures.contains)
    }

    public var isEligibleForComplete: Bool {
        let rawProducts = purchasedProducts.compactMap {
            ABI.AppProduct(rawValue: $0.rawValue)
        }

        //
        // allow purchasing complete products only if:
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
        userLevel == .beta || isPayingUser
#endif
    }

    public var isPayingUser: Bool {
        !purchasedProducts.isEmpty
    }

    public var didPurchaseComplete: Bool {
        purchasedProducts.contains(where: \.isComplete)
    }

    public func didPurchase(_ purchasable: InAppProduct) -> Bool {
        guard let product = ABI.AppProduct(rawValue: purchasable.productIdentifier) else {
            return false
        }
        return purchasedProducts.contains(product)
    }

    public func didPurchase(_ purchasable: [InAppProduct]) -> Bool {
        purchasable.allSatisfy {
            didPurchase($0)
        }
    }
}

// MARK: - Receipt

private extension IAPManager {
    func asyncReloadReceipt() async {
        pp_log_g(.App.iap, .notice, "Start reloading in-app receipt...")

        var originalPurchase: OriginalPurchase?
        var purchasedProducts: Set<ABI.AppProduct> = []
        var eligibleFeatures: Set<ABI.AppFeature> = []

        if let receipt = await receiptReader.receipt(at: userLevel) {
            originalPurchase = receipt.originalPurchase

            if let originalPurchase {
                pp_log_g(.App.iap, .info, "Original purchase: \(originalPurchase)")

                // assume some purchases by build number
                let entitled = productsAtBuild?(originalPurchase) ?? []
                pp_log_g(.App.iap, .notice, "Entitled features: \(entitled.map(\.rawValue))")

                entitled.forEach {
                    purchasedProducts.insert($0)
                }
            }
            if let iapReceipts = receipt.purchaseReceipts {
                pp_log_g(.App.iap, .info, "Process in-app purchase receipts...")

                let products: [ABI.AppProduct] = iapReceipts.compactMap {
                    guard let pid = $0.productIdentifier else {
                        return nil
                    }
                    guard let product = ABI.AppProduct(rawValue: pid) else {
                        pp_log_g(.App.iap, .debug, "\tDiscard unknown product identifier: \(pid)")
                        return nil
                    }
                    if let expirationDate = $0.expirationDate {
                        let now = Date()
                        pp_log_g(.App.iap, .debug, "\t\(pid) [expiration date: \(expirationDate), now: \(now)]")
                        if now >= expirationDate {
                            pp_log_g(.App.iap, .info, "\t\(pid) [expired on: \(expirationDate)]")
                            return nil
                        }
                    }
                    if let cancellationDate = $0.cancellationDate {
                        pp_log_g(.App.iap, .info, "\t\(pid) [cancelled on: \(cancellationDate)]")
                        return nil
                    }
                    if let purchaseDate = $0.originalPurchaseDate {
                        pp_log_g(.App.iap, .info, "\t\(pid) [purchased on: \(purchaseDate)]")
                    }
                    return product
                }

                products.forEach {
                    purchasedProducts.insert($0)
                }
            }

            eligibleFeatures = purchasedProducts.reduce(into: []) { eligible, product in
                product.features.forEach {
                    eligible.insert($0)
                }
            }
        } else {
            pp_log_g(.App.iap, .error, "Could not parse App Store receipt!")
        }

        userLevel.features.forEach {
            eligibleFeatures.insert($0)
        }
        unrestrictedFeatures.forEach {
            eligibleFeatures.insert($0)
        }

        pp_log_g(.App.iap, .notice, "Finished reloading in-app receipt for user level \(userLevel)")
        pp_log_g(.App.iap, .notice, "\tOriginal purchase: \(String(describing: originalPurchase))")
        pp_log_g(.App.iap, .notice, "\tPurchased products: \(purchasedProducts.map(\.rawValue))")
        pp_log_g(.App.iap, .notice, "\tEligible features: \(eligibleFeatures)")

        self.originalPurchase = originalPurchase
        self.purchasedProducts = purchasedProducts
        self.eligibleFeatures = eligibleFeatures // Will call objectWillChange.send()
    }
}

// MARK: - Observation

extension IAPManager {
    public func observeObjects(withProducts: Bool = true) {
        Task {
            await fetchLevelIfNeeded()
            do {
                inAppHelper
                    .didUpdate
                    .receive(on: DispatchQueue.main)
                    .sink { [weak self] in
                        Task {
                            await self?.reloadReceipt()
                        }
                    }
                    .store(in: &subscriptions)

                if withProducts {
                    let products = try await inAppHelper.fetchProducts(timeout: timeoutInterval)
                    pp_log_g(.App.iap, .info, "Available in-app products: \(products.map(\.key))")
                }
            } catch is TaskTimeoutError {
                throw ABI.AppError.timeout
            } catch {
                pp_log_g(.App.iap, .error, "Unable to fetch in-app products: \(error)")
            }
        }
    }

    public func fetchLevelIfNeeded() async {
        guard isEnabled else {
            userLevel = .freemium
            return
        }
        guard userLevel == .undefined else {
            return
        }
        if let customUserLevel {
            userLevel = customUserLevel
            pp_log_g(.App.iap, .info, "App level (custom): \(userLevel)")
            return
        }
        let isBeta = await betaChecker.isBeta()
        guard userLevel == .undefined else {
            return
        }
        userLevel = isBeta ? .beta : .freemium
        pp_log_g(.App.iap, .info, "App level: \(userLevel)")
    }
}
