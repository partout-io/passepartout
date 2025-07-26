// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import Combine
import Foundation

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

    public let localizedPrice: String

    public let native: Sendable?

    public init(productIdentifier: String, localizedTitle: String, localizedPrice: String, native: Sendable?) {
        self.productIdentifier = productIdentifier
        self.localizedTitle = localizedTitle
        self.localizedPrice = localizedPrice
        self.native = native
    }
}

public protocol InAppHelper {
    associatedtype ProductType: Hashable

    var canMakePurchases: Bool { get }

    var didUpdate: AnyPublisher<Void, Never> { get }

    func fetchProducts(timeout: Int) async throws -> [ProductType: InAppProduct]

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

public protocol InAppReceiptReader {
    func receipt() async -> InAppReceipt?
}
