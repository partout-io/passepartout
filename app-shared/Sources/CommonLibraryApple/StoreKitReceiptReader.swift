// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import StoreKit

public final class StoreKitReceiptReader: InAppReceiptReader, Sendable {
    public init() {}

    public func receipt() async -> ABI.StoreReceipt? {
        let result = await entitlements()

        let purchaseReceipts = result.txs
            .compactMap {
                ABI.StoreReceipt.PurchaseReceipt(
                    productIdentifier: $0.productID,
                    expirationDate: $0.expirationDate,
                    cancellationDate: $0.revocationDate,
                    originalPurchaseDate: $0.originalPurchaseDate
                )
            }

        return ABI.StoreReceipt(
            originalPurchase: result.purchase,
            purchaseReceipts: purchaseReceipts
        )
    }
}

private extension StoreKitReceiptReader {
    func entitlements() async -> (purchase: ABI.OriginalPurchase?, txs: [Transaction]) {
        async let build = Task {
            let startDate = Date()
            pspLog(.iap, .debug, "Start fetching original build number...")
            let originalPurchase: ABI.OriginalPurchase?
            do {
                switch try await AppTransaction.shared {
                case .verified(let tx):
                    pspLog(.iap, .debug, "Fetched AppTransaction: \(tx)")
                    originalPurchase = tx.originalPurchase
                case .unverified(let tx, let error):
                    let json = String(data: tx.jsonRepresentation, encoding: .utf8)
                    pspLog(.iap, .error, "Unable to process transaction: \(error), json=\(json ?? "")")
                    originalPurchase = nil
                }
            } catch {
                originalPurchase = nil
            }
            let elapsed = -startDate.timeIntervalSinceNow
            pspLog(.iap, .debug, "Fetched original build number: \(elapsed)")
            return originalPurchase
        }
        async let txs = Task {
            let startDate = Date()
            pspLog(.iap, .debug, "Start fetching transactions...")
            var transactions: [Transaction] = []
            for await entitlement in Transaction.currentEntitlements {
                switch entitlement {
                case .verified(let tx):
                    transactions.append(tx)
                case .unverified(let tx, let error):
                    let json = String(data: tx.jsonRepresentation, encoding: .utf8)
                    pspLog(.iap, .error, "Unable to process transaction: \(error), json=\(json ?? "")")
                }
            }
            let elapsed = -startDate.timeIntervalSinceNow
            pspLog(.iap, .debug, "Fetched transactions: \(elapsed)")
            return transactions
        }
        return await (build.value, txs.value)
    }
}

private extension AppTransaction {
    var originalPurchase: ABI.OriginalPurchase? {
        guard ![.sandbox, .xcode].contains(environment) else {
            return nil
        }
        return ABI.OriginalPurchase(
            buildNumber: Int(originalAppVersion) ?? .max,
            purchaseDate: originalPurchaseDate
        )
    }
}
