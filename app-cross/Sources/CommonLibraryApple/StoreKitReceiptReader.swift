// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import StoreKit

public final class StoreKitReceiptReader: InAppReceiptReader, Sendable {
    public enum Mode: Sendable {
        case uncached

        var isCaching: Bool {
            self != .uncached
        }
    }

    private let modeBlock: @Sendable @BusinessActor () async -> StoreKitReceiptReader.Mode

    public init(
        modeBlock: @escaping @Sendable @BusinessActor () async -> StoreKitReceiptReader.Mode
    ) {
        self.modeBlock = modeBlock
    }

    public func receipt() async -> ABI.StoreReceipt? {
        let mode = await modeBlock()
        pspLog(.iap, .info, "Using StoreKit receipt mode: \(mode)")
        let result = await entitlements(for: mode)
        guard result.hasFreshEvidence else {
            pspLog(.iap, .error, "Unable to determine StoreKit receipt state")
            return nil
        }
        let originalPurchase = result.originalPurchase
        let purchaseReceipts = result.purchaseReceipts
        return ABI.StoreReceipt(
            originalPurchase: originalPurchase,
            purchaseReceipts: purchaseReceipts
        )
    }
}

// MARK: - Entitlements

private extension StoreKitReceiptReader {
    struct TransactionEvidence {
        let tx: Transaction
        let jws: String?
    }

    struct EntitlementsResult {
        let originalPurchase: ABI.OriginalPurchase?
        let appTransactionJWS: String?
        let didFetchAppTransaction: Bool
        let transactions: [TransactionEvidence]

        var purchaseReceipts: [ABI.StoreReceipt.PurchaseReceipt]? {
            let receipts = transactions.map {
                ABI.StoreReceipt.PurchaseReceipt(
                    productIdentifier: $0.tx.productID,
                    expirationDate: $0.tx.expirationDate,
                    cancellationDate: $0.tx.revocationDate,
                    originalPurchaseDate: $0.tx.originalPurchaseDate
                )
            }
            return !receipts.isEmpty ? receipts : nil
        }

        var hasFreshEvidence: Bool {
            didFetchAppTransaction || !transactions.isEmpty
        }
    }

    func entitlements(for mode: Mode) async -> EntitlementsResult {
        async let build = Task {
            let startDate = Date()
            pspLog(.iap, .debug, "Start fetching original transaction...")
            let result: (purchase: ABI.OriginalPurchase?, jws: String?, didFetch: Bool)
            do {
                let appTransaction = try await AppTransaction.shared
                let jws = mode.isCaching ? appTransaction.jwsRepresentation : nil
                switch appTransaction {
                case .verified(let tx):
                    pspLog(.iap, .debug, "Fetched original transaction: \(tx)")
                    result = (tx.originalPurchase, jws, true)
                case .unverified(let tx, let error):
                    let json = String(data: tx.jsonRepresentation, encoding: .utf8)
                    pspLog(.iap, .error, "Unable to process original transaction: \(error), json=\(json ?? "")")
                    result = (nil, nil, false)
                }
            } catch {
                pspLog(.iap, .error, "Unable to fetch original transaction: \(error)")
                result = (nil, nil, false)
            }
            let elapsed = -startDate.timeIntervalSinceNow
            pspLog(.iap, .debug, "Fetched original transaction in \(elapsed)")
            return result
        }
        async let txs = Task {
            let startDate = Date()
            pspLog(.iap, .debug, "Start fetching transactions...")
            var transactions: [TransactionEvidence] = []
            for await entitlement in Transaction.currentEntitlements {
                switch entitlement {
                case .verified(let tx):
                    let jws = mode.isCaching ? entitlement.jwsRepresentation : nil
                    let result = TransactionEvidence(tx: tx, jws: jws)
                    transactions.append(result)
                case .unverified(let tx, let error):
                    let json = String(data: tx.jsonRepresentation, encoding: .utf8)
                    pspLog(.iap, .error, "Unable to process transaction: \(error), json=\(json ?? "")")
                }
            }
            let elapsed = -startDate.timeIntervalSinceNow
            pspLog(.iap, .debug, "Fetched transactions in \(elapsed)")
            return transactions
        }
        let result = await (build.value, txs.value)
        return EntitlementsResult(
            originalPurchase: result.0.purchase,
            appTransactionJWS: result.0.jws,
            didFetchAppTransaction: result.0.didFetch,
            transactions: result.1
        )
    }
}

// MARK: - Extensions

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
