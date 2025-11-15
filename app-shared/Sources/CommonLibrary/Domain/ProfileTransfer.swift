// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

extension ABI {
    public struct ProfileTransfer: Hashable, Codable, Sendable {
        public let received: Int

        public let sent: Int

        init(received: Int, sent: Int) {
            self.received = received
            self.sent = sent
        }
    }
}
