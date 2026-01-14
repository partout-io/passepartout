// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import Partout

extension ABI {
    public struct AppProfile: Identifiable, Hashable, Sendable {
        // FIXME: #1594, Dumb wrapping, should not be public
        public let native: Profile

        public var id: ABI.AppIdentifier {
            native.id
        }

        public init(native: Profile) {
            self.native = native
        }
    }
}
