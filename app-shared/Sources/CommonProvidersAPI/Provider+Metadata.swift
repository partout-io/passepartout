// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import Partout

extension Provider {
    public struct Metadata: Hashable, Codable, Sendable {
        public let userInfo: JSON?

        public init(userInfo: JSON? = nil) {
            self.userInfo = userInfo
        }
    }
}
