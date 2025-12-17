// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#if !PSP_MONOLITH
import CommonLibraryCore
#endif
import Foundation
import StoreKit

public final class StoreKitReceiptReader: InAppReceiptReader, Sendable {
    private let logger: AppLogger

    public init(logger: AppLogger) {
        self.logger = logger
    }

    public func receipt() async -> InAppReceipt? {
        let result = await entitlements()

        let purchaseReceipts = result.txs
            .compactMap {
                InAppReceipt.PurchaseReceipt(
                    productIdentifier: $0.productID,
                    expirationDate: $0.expirationDate,
                    cancellationDate: $0.revocationDate,
                    originalPurchaseDate: $0.originalPurchaseDate
                )
            }

        return InAppReceipt(originalPurchase: result.purchase, purchaseReceipts: purchaseReceipts)
    }
}

private extension StoreKitReceiptReader {
    func entitlements() async -> (purchase: OriginalPurchase?, txs: [Transaction]) {
        async let build = Task {
            let startDate = Date()
            logger.log(.iap, .debug, "Start fetching original build number...")
            let originalPurchase: OriginalPurchase?
            do {
                switch try await AppTransaction.shared {
                case .verified(let tx):
                    logger.log(.iap, .debug, "Fetched AppTransaction: \(tx)")
                    originalPurchase = tx.originalPurchase
                case .unverified(let tx, let error):
                    let json = String(data: tx.jsonRepresentation, encoding: .utf8)
                    logger.log(.iap, .error, "Unable to process transaction: \(error), json=\(json ?? "")")
                    originalPurchase = nil
                }
            } catch {
                originalPurchase = nil
            }
            let elapsed = -startDate.timeIntervalSinceNow
            logger.log(.iap, .debug, "Fetched original build number: \(elapsed)")
            return originalPurchase
        }
        async let txs = Task {
            let startDate = Date()
            logger.log(.iap, .debug, "Start fetching transactions...")
            var transactions: [Transaction] = []
            for await entitlement in Transaction.currentEntitlements {
                switch entitlement {
                case .verified(let tx):
                    transactions.append(tx)
                case .unverified(let tx, let error):
                    let json = String(data: tx.jsonRepresentation, encoding: .utf8)
                    logger.log(.iap, .error, "Unable to process transaction: \(error), json=\(json ?? "")")
                }
            }
            let elapsed = -startDate.timeIntervalSinceNow
            logger.log(.iap, .debug, "Fetched transactions: \(elapsed)")
            return transactions
        }
        return await (build.value, txs.value)
    }
}

private extension AppTransaction {
    var originalPurchase: OriginalPurchase? {
        guard ![.sandbox, .xcode].contains(environment) else {
            return nil
        }
        return OriginalPurchase(
            buildNumber: Int(originalAppVersion) ?? .max,
            purchaseDate: originalPurchaseDate
        )
    }
}
