// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import Combine

import Foundation

public actor FakeAppProductHelper: AppProductHelper {
    private let purchase: OriginalPurchase

    public private(set) var products: [ABI.AppProduct: InAppProduct]

    public nonisolated let receiptReader: FakeAppReceiptReader

    private nonisolated let didUpdateSubject: PassthroughSubject<Void, Never>

    // set .max to skip entitled products
    public init(build: Int = .max) {
        purchase = OriginalPurchase(buildNumber: build)
        products = [:]
        receiptReader = FakeAppReceiptReader()
        didUpdateSubject = PassthroughSubject()
    }

    public nonisolated var canMakePurchases: Bool {
        true
    }

    public nonisolated var didUpdate: AnyPublisher<Void, Never> {
        didUpdateSubject.eraseToAnyPublisher()
    }

    public func fetchProducts(timeout: TimeInterval) async throws -> [ABI.AppProduct: InAppProduct] {
        products = ABI.AppProduct.all.reduce(into: [:]) {
            $0[$1] = $1.asFakeIAP
        }
        await receiptReader.setReceipt(withPurchase: purchase, identifiers: [])
        didUpdateSubject.send()
        return products
    }

    public func purchase(_ inAppProduct: InAppProduct) async throws -> InAppPurchaseResult {
        await receiptReader.addPurchase(with: inAppProduct.productIdentifier)
        didUpdateSubject.send()
        return .done
    }

    public func restorePurchases() async throws {
        didUpdateSubject.send()
    }
}

extension ABI.AppProduct {
    public var asFakeIAP: InAppProduct {
        InAppProduct(
            productIdentifier: rawValue,
            localizedTitle: rawValue,
            localizedDescription: rawValue,
            localizedPrice: "€10.0",
            native: self
        )
    }
}
