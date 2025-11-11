// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonUtils
import Foundation

public actor FakeAppReceiptReader: ABI.AppReceiptReader {
    private var localReceipt: InAppReceipt?

    public init(receipt localReceipt: InAppReceipt? = nil) {
        self.localReceipt = localReceipt
    }

    public func setReceipt(withBuild build: Int, products: Set<ABI.AppProduct>, cancelledProducts: Set<ABI.AppProduct> = []) {
        setReceipt(withPurchase: OriginalPurchase(buildNumber: build), products: products, cancelledProducts: cancelledProducts)
    }

    public func setReceipt(withPurchase purchase: OriginalPurchase, products: Set<ABI.AppProduct>, cancelledProducts: Set<ABI.AppProduct> = []) {
        setReceipt(
            withPurchase: purchase,
            identifiers: Set(products.map(\.rawValue)),
            cancelledIdentifiers: Set(cancelledProducts.map(\.rawValue))
        )
    }

    public func setReceipt(withBuild build: Int, identifiers: Set<String>, cancelledIdentifiers: Set<String> = []) {
        setReceipt(withPurchase: OriginalPurchase(buildNumber: build), identifiers: identifiers, cancelledIdentifiers: cancelledIdentifiers)
    }

    public func setReceipt(withPurchase purchase: OriginalPurchase, identifiers: Set<String>, cancelledIdentifiers: Set<String> = []) {
        localReceipt = InAppReceipt(originalPurchase: purchase, purchaseReceipts: identifiers.map {
            .init(
                productIdentifier: $0,
                expirationDate: nil,
                cancellationDate: cancelledIdentifiers.contains($0) ? Date() : nil,
                originalPurchaseDate: nil
            )
        })
    }

    public func receipt(at userLevel: ABI.AppUserLevel) async -> InAppReceipt? {
        localReceipt
    }

    public func addPurchase(with identifier: String) async {
        await addPurchase(with: identifier, expirationDate: nil, cancellationDate: nil)
    }
}

extension FakeAppReceiptReader {
    public func addPurchase(
        with product: ABI.AppProduct,
        expirationDate: Date? = nil,
        cancellationDate: Date? = nil
    ) async {
        await addPurchase(
            with: product.rawValue,
            expirationDate: expirationDate,
            cancellationDate: cancellationDate
        )
    }

    public func addPurchase(
        with identifier: String,
        expirationDate: Date? = nil,
        cancellationDate: Date? = nil
    ) async {
        var purchaseReceipts = localReceipt?.purchaseReceipts ?? []
        purchaseReceipts.append(.init(
            productIdentifier: identifier,
            expirationDate: expirationDate,
            cancellationDate: cancellationDate,
            originalPurchaseDate: nil
        ))
        let newReceipt = InAppReceipt(
            originalPurchase: localReceipt?.originalPurchase,
            purchaseReceipts: purchaseReceipts
        )
        self.localReceipt = newReceipt
    }
}
