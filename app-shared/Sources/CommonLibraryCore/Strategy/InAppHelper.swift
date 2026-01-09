// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

public protocol InAppHelper: Sendable {
    var canMakePurchases: Bool { get }

    var didUpdate: AsyncStream<Void> { get }

    func fetchProducts(timeout: TimeInterval) async throws -> [ABI.AppProduct: ABI.StoreProduct]

    func purchase(_ storeProduct: ABI.StoreProduct) async throws -> ABI.StoreResult

    func restorePurchases() async throws
}
