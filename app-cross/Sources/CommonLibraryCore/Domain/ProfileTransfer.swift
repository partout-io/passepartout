// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

extension ABI {
    public struct ProfileTransfer: Hashable, Sendable {
        public let received: Int
        public let sent: Int

        public init(received: Int = 0, sent: Int = 0) {
            self.received = received
            self.sent = sent
        }
    }
}
