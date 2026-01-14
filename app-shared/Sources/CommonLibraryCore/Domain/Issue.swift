// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import MiniFoundation

extension ABI {
    public struct Issue: Identifiable, Sendable {
        public let id: UUID

        public let comment: String

        public let appLine: String?

        public let purchasedProducts: Set<ABI.AppProduct>

        public let providerLastUpdates: [ProviderID: UInt32]

        public let appLog: Data?

        public let tunnelLog: Data?

        public let osLine: String

        public let deviceLine: String?

        public init(
            comment: String,
            appLine: String?,
            purchasedProducts: Set<ABI.AppProduct>,
            providerLastUpdates: [ProviderID: UInt32] = [:],
            appLog: Data? = nil,
            tunnelLog: Data? = nil
        ) {
            id = UUID()
            self.comment = comment
            self.appLine = appLine
            self.purchasedProducts = purchasedProducts
            self.appLog = appLog
            self.tunnelLog = tunnelLog
            self.providerLastUpdates = providerLastUpdates

            let systemInfo = SystemInformation()
            osLine = systemInfo.osString
            deviceLine = systemInfo.deviceString
        }
    }
}
