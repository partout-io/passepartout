// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import MiniFoundation
import StoreKit

@MainActor
public final class StoreKitHelper: InAppHelper {
    private let products: [ABI.AppProduct]

    private let inAppIdentifier: @Sendable (ABI.AppProduct) -> String

    private var activeTransactions: Set<Transaction>

    private nonisolated let didUpdateSubject: PassthroughStream<UniqueID, Void>

    private var observer: Task<Void, Never>?

    public init(products: [ABI.AppProduct], inAppIdentifier: @escaping @Sendable (ABI.AppProduct) -> String) {
        self.products = products
        self.inAppIdentifier = inAppIdentifier
        activeTransactions = []
        didUpdateSubject = PassthroughStream()

        observer = transactionsObserverTask()
    }

    deinit {
        observer?.cancel()
    }
}

extension StoreKitHelper {
    public nonisolated var canMakePurchases: Bool {
        AppStore.canMakePayments
    }

    public nonisolated var didUpdate: AsyncStream<Void> {
        didUpdateSubject.subscribe()
    }

    public func fetchProducts(timeout: TimeInterval) async throws -> [ABI.AppProduct: ABI.StoreProduct] {
        let skProducts = try await performTask(withTimeout: timeout) {
            try await Product.products(for: self.products.map(self.inAppIdentifier))
        }
        return skProducts.reduce(into: [:]) {
            guard let pid = ABI.AppProduct(rawValue: $1.id) else {
                return
            }
            $0[pid] = ABI.StoreProduct(
                product: pid,
                localizedTitle: $1.displayName,
                localizedDescription: $1.description,
                localizedPrice: $1.displayPrice,
                nativeIdentifier: $1.id,
                native: $1
            )
        }
    }

    public func purchase(_ storeProduct: ABI.StoreProduct) async throws -> ABI.StoreResult {
        guard let skProduct = storeProduct.native as? Product else {
            return .notFound
        }
        switch try await skProduct.purchase() {
        case .success(let verificationResult):
            guard let transaction = try? verificationResult.payloadValue else {
                break
            }
            activeTransactions.insert(transaction)
            didUpdateSubject.send()
            await transaction.finish()
            return .done

        case .pending:
            return .pending

        case .userCancelled:
            break

        @unknown default:
            break
        }
        return .cancelled
    }

    public func restorePurchases() async throws {
        do {
            try await AppStore.sync()
        } catch StoreKitError.userCancelled {
            //
        }
    }
}

private extension StoreKitHelper {
    nonisolated func transactionsObserverTask() -> Task<Void, Never> {
        Task {
            for await update in Transaction.updates {
                guard let transaction = try? update.payloadValue else {
                    continue
                }
                await fetchActiveTransactions()
                await transaction.finish()
                guard !Task.isCancelled else {
                    break
                }
            }
        }
    }

    func fetchActiveTransactions() async {
        var activeTransactions: Set<Transaction> = []
        for await entitlement in Transaction.currentEntitlements {
            if let transaction = try? entitlement.payloadValue {
                activeTransactions.insert(transaction)
            }
        }
        self.activeTransactions = activeTransactions
        didUpdateSubject.send()
    }
}
