// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#if !PSP_CROSS
extension IAPManager: ObservableObject {}
#endif

@MainActor
public final class IAPManager {
    private let customUserLevel: ABI.AppUserLevel?

    private let inAppHelper: InAppHelper

    private let receiptReader: UserInAppReceiptReader

    private let betaChecker: BetaChecker

    private let unrestrictedFeatures: Set<ABI.AppFeature>

    private let timeoutInterval: TimeInterval

    private let verificationDelayMinutesBlock: @Sendable (Bool) -> Int

    private let productsAtBuild: BuildProducts?

#if !PSP_CROSS
    // FIXME: #1594, AppContext requires Published
    @Published
#endif
    public var isEnabled = true {
        didSet {
            pendingReceiptTask?.cancel()
            didChange.send(.status(isEnabled: isEnabled))
        }
    }

    private(set) var userLevel: ABI.AppUserLevel

    public private(set) var originalPurchase: ABI.OriginalPurchase?

    public private(set) var purchasedProducts: Set<ABI.AppProduct>

#if !PSP_CROSS
    // FIXME: #1594, AppContext requires Published
    @Published
#endif
    public private(set) var eligibleFeatures: Set<ABI.AppFeature> {
        didSet {
            didChange.send(.eligibleFeatures(eligibleFeatures))
        }
    }

    public var verificationDelayMinutes: Int {
        verificationDelayMinutesBlock(isBeta)
    }

    public let didChange: PassthroughStream<UniqueID, ABI.IAPEvent>

    private var isObserving: Bool

    private var pendingReceiptTask: Task<Void, Never>? {
        willSet {
#if !PSP_CROSS
            objectWillChange.send()
#endif
        }
        didSet {
            didChange.send(.loadReceipt(isLoading: pendingReceiptTask != nil))
        }
    }

    private var receiptSubscription: Task<Void, Never>?

    // Dummy
    public init() {
        customUserLevel = nil
        inAppHelper = FakeInAppHelper()
        receiptReader = FakeInAppReceiptReader()
        betaChecker = FakeBetaChecker()
        unrestrictedFeatures = []
        timeoutInterval = 0.0
        verificationDelayMinutesBlock = { _ in 0 }
        productsAtBuild = nil
        userLevel = .undefined
        purchasedProducts = []
        eligibleFeatures = []
        didChange = PassthroughStream()
        isObserving = false
        isEnabled = false
    }

    public init(
        customUserLevel: ABI.AppUserLevel? = nil,
        inAppHelper: InAppHelper,
        receiptReader: UserInAppReceiptReader,
        betaChecker: BetaChecker,
        unrestrictedFeatures: Set<ABI.AppFeature> = [],
        timeoutInterval: TimeInterval,
        verificationDelayMinutesBlock: @escaping @Sendable (Bool) -> Int,
        productsAtBuild: BuildProducts? = nil
    ) {
        self.customUserLevel = customUserLevel
        self.inAppHelper = inAppHelper
        self.receiptReader = receiptReader
        self.betaChecker = betaChecker
        self.unrestrictedFeatures = unrestrictedFeatures
        self.timeoutInterval = timeoutInterval
        self.verificationDelayMinutesBlock = verificationDelayMinutesBlock
        self.productsAtBuild = productsAtBuild
        userLevel = .undefined
        purchasedProducts = []
        eligibleFeatures = []
        didChange = PassthroughStream()
        isObserving = false
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

    public func fetchPurchasableProducts(for products: [ABI.AppProduct]) async throws -> [ABI.StoreProduct] {
        guard isEnabled else { return [] }
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

    public func purchase(_ storeProduct: ABI.StoreProduct) async throws -> ABI.StoreResult {
        guard isEnabled else {
            return .cancelled
        }
        let result = try await inAppHelper.purchase(storeProduct)
        if result == .done {
            await receiptReader.addPurchase(with: storeProduct.nativeIdentifier)
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

    public func didPurchase(_ product: ABI.AppProduct) -> Bool {
        purchasedProducts.contains(product)
    }

    public func didPurchase(_ products: [ABI.AppProduct]) -> Bool {
        products.allSatisfy(didPurchase)
    }
}

// MARK: - Receipt

private extension IAPManager {
    func asyncReloadReceipt() async {
        pp_log_g(.App.iap, .notice, "Start reloading in-app receipt...")

        var originalPurchase: ABI.OriginalPurchase?
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
        // This method must be called EXACTLY once
        precondition(!isObserving)
        isObserving = true
        let inAppEvents = inAppHelper.didUpdate
        Task {
            await fetchLevelIfNeeded()
            do {
                // Reload the receipt on in-app updates
                receiptSubscription = Task { [weak self] in
                    guard let self else { return }
                    for await _ in inAppEvents {
                        await reloadReceipt()
                    }
                }

                // Fetch the available products
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
