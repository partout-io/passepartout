// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#if !PSP_MONOLITH
import CommonProvidersCore
#endif
import Partout

extension Provider {
    public struct Metadata: Hashable, Codable, Sendable {
        public let userInfo: JSON?

        public init(userInfo: JSON? = nil) {
            self.userInfo = userInfo
        }
    }
}
