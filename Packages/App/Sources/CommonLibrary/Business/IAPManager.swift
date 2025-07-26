// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import Combine
import CommonUtils
import Foundation

@MainActor
public final class IAPManager: ObservableObject {
    private let customUserLevel: AppUserLevel?

    private let inAppHelper: any AppProductHelper

    private let receiptReader: AppReceiptReader

    private let betaChecker: BetaChecker

    private let unrestrictedFeatures: Set<AppFeature>

    private let productsAtBuild: BuildProducts<AppProduct>?

    @Published
    public var isEnabled = true {
        didSet {
            pendingReceiptTask?.cancel()
        }
    }

    private(set) var userLevel: AppUserLevel

    public private(set) var originalPurchase: OriginalPurchase?

    public private(set) var purchasedProducts: Set<AppProduct>

    @Published
    public private(set) var eligibleFeatures: Set<AppFeature>

    @Published
    private var pendingReceiptTask: Task<Void, Never>?

    private var subscriptions: Set<AnyCancellable>

    public init(
        customUserLevel: AppUserLevel? = nil,
        inAppHelper: any AppProductHelper,
        receiptReader: AppReceiptReader,
        betaChecker: BetaChecker,
        unrestrictedFeatures: Set<AppFeature> = [],
        productsAtBuild: BuildProducts<AppProduct>? = nil
    ) {
        self.customUserLevel = customUserLevel
        self.inAppHelper = inAppHelper
        self.receiptReader = receiptReader
        self.betaChecker = betaChecker
        self.unrestrictedFeatures = unrestrictedFeatures
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

    public func purchasableProducts(for products: [AppProduct]) async throws -> [InAppProduct] {
        guard isEnabled else {
            return []
        }
        do {
            let inAppProducts = try await inAppHelper.fetchProducts(timeout: Constants.shared.iap.productsTimeoutInterval)
            return products.compactMap {
                inAppProducts[$0]
            }
        } catch is TaskTimeoutError {
            throw AppError.timeout
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

    public func isEligible(for feature: AppFeature) -> Bool {
        eligibleFeatures.contains(feature)
    }

    public func isEligible<C>(for features: C) -> Bool where C: Collection, C.Element == AppFeature {
        if features.isEmpty {
            return true
        }
        return features.allSatisfy(eligibleFeatures.contains)
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
}

// MARK: - Receipt

private extension IAPManager {
    func asyncReloadReceipt() async {
        pp_log_g(.App.iap, .notice, "Start reloading in-app receipt...")

        var originalPurchase: OriginalPurchase?
        var purchasedProducts: Set<AppProduct> = []
        var eligibleFeatures: Set<AppFeature> = []

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

                let products: [AppProduct] = iapReceipts.compactMap {
                    guard let pid = $0.productIdentifier else {
                        return nil
                    }
                    guard let product = AppProduct(rawValue: pid) else {
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
        self.eligibleFeatures = eligibleFeatures // @Published -> objectWillChange.send()
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
                    let products = try await inAppHelper.fetchProducts(timeout: Constants.shared.iap.productsTimeoutInterval)
                    pp_log_g(.App.iap, .info, "Available in-app products: \(products.map(\.key))")
                }
            } catch is TaskTimeoutError {
                throw AppError.timeout
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
