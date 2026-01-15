// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import Partout

extension ABI {
    public struct StoreReceipt: Sendable {
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
}
