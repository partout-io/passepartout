// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import Partout

extension ABI {
    public struct OriginalPurchase: Equatable, Sendable {
        public let buildNumber: Int

        public let purchaseDate: Date

        public init(buildNumber: Int, purchaseDate: Date = .distantFuture) {
            self.buildNumber = buildNumber
            self.purchaseDate = purchaseDate
        }
    }
}

extension ABI.OriginalPurchase: CustomStringConvertible {
    public var description: String {
        let build = buildNumber == .max ? "unknown" : String(buildNumber)
        return "OriginalPurchase(buildNumber: \(build), purchaseDate: \(purchaseDate))"
    }
}
