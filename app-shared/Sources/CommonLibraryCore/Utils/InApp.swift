// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

public enum InAppPurchaseResult: Sendable {
    case done

    case pending

    case notFound

    case cancelled
}

public enum InAppError: Error {
    case unknown
}

public struct InAppProduct: Sendable {
    public let productIdentifier: String

    public let localizedTitle: String

    public let localizedDescription: String

    public let localizedPrice: String

    public let native: Sendable?

    public init(productIdentifier: String, localizedTitle: String, localizedDescription: String, localizedPrice: String, native: Sendable?) {
        self.productIdentifier = productIdentifier
        self.localizedTitle = localizedTitle
        self.localizedDescription = localizedDescription
        self.localizedPrice = localizedPrice
        self.native = native
    }
}

public protocol InAppHelper: Sendable {
    associatedtype ProductType: Hashable

    var canMakePurchases: Bool { get }

    var didUpdate: AsyncStream<Void> { get }

    func fetchProducts(timeout: TimeInterval) async throws -> [ProductType: InAppProduct]

    func purchase(_ inAppProduct: InAppProduct) async throws -> InAppPurchaseResult

    func restorePurchases() async throws
}

public struct InAppReceipt: Sendable {
    public struct PurchaseReceipt: Sendable {
        public let productIdentifier: String?

        public let expirationDate: Date?

        public let cancellationDate: Date?

        public let originalPurchaseDate: Date?

        public init(productIdentifier: String?, expirationDate: Date?, cancellationDate: Date?, originalPurchaseDate: Date?) {
            self.productIdentifier = productIdentifier
            self.expirationDate = expirationDate
            self.cancellationDate = cancellationDate
            self.originalPurchaseDate = originalPurchaseDate
        }
    }

    public let originalPurchase: OriginalPurchase?

    public let purchaseReceipts: [PurchaseReceipt]?

    public init(originalPurchase: OriginalPurchase?, purchaseReceipts: [PurchaseReceipt]?) {
        self.originalPurchase = originalPurchase
        self.purchaseReceipts = purchaseReceipts
    }

    public func withOriginalPurchase(_ purchase: OriginalPurchase) -> Self {
        .init(
            originalPurchase: purchase,
            purchaseReceipts: purchaseReceipts
        )
    }
}

public protocol InAppReceiptReader: Sendable {
    func receipt() async -> InAppReceipt?
}
