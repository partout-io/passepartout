// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import MiniFoundation

public actor FakeInAppHelper: InAppHelper {
    private let purchase: ABI.OriginalPurchase

    private var products: [ABI.AppProduct: ABI.StoreProduct]

    public nonisolated let receiptReader: FakeInAppReceiptReader

    private nonisolated let didUpdateSubject: PassthroughStream<UUID, Void>

    // set .max to skip entitled products
    public init(build: Int = .max) {
        purchase = ABI.OriginalPurchase(buildNumber: build)
        products = [:]
        receiptReader = FakeInAppReceiptReader()
        didUpdateSubject = PassthroughStream()
    }

    public nonisolated var canMakePurchases: Bool {
        true
    }

    public nonisolated var didUpdate: AsyncStream<Void> {
        didUpdateSubject.subscribe()
    }

    public func fetchProducts(timeout: TimeInterval) async throws -> [ABI.AppProduct: ABI.StoreProduct] {
        products = ABI.AppProduct.all.reduce(into: [:]) {
            $0[$1] = $1.asFakeStoreProduct
        }
        await receiptReader.setReceipt(withPurchase: purchase, identifiers: [])
        didUpdateSubject.send()
        return products
    }

    public func purchase(_ inAppProduct: ABI.StoreProduct) async throws -> ABI.StoreResult {
        await receiptReader.addPurchase(with: inAppProduct.nativeIdentifier)
        didUpdateSubject.send()
        return .done
    }

    public func restorePurchases() async throws {
        didUpdateSubject.send()
    }
}

extension ABI.AppProduct {
    public var asFakeStoreProduct: ABI.StoreProduct {
        ABI.StoreProduct(
            product: self,
            localizedTitle: rawValue,
            localizedDescription: rawValue,
            localizedPrice: "€10.0",
            nativeIdentifier: rawValue,
            native: nil
        )
    }
}
