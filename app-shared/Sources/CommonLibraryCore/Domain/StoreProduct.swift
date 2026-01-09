// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

extension ABI {
    public struct StoreProduct: Sendable {
        public let product: AppProduct
        public let localizedTitle: String
        public let localizedDescription: String
        public let localizedPrice: String
        public let nativeIdentifier: String
        public let native: Sendable?

        public init(
            product: AppProduct,
            localizedTitle: String,
            localizedDescription: String,
            localizedPrice: String,
            nativeIdentifier: String,
            native: Sendable?
        ) {
            self.product = product
            self.localizedTitle = localizedTitle
            self.localizedDescription = localizedDescription
            self.localizedPrice = localizedPrice
            self.nativeIdentifier = nativeIdentifier
            self.native = native
        }
    }
}
