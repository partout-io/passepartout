// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import Partout

// FIXME: #1594, Dumb wrappings, should not be public
extension ABI {
    public struct AppProfile: Identifiable, Hashable, Sendable {
        public let native: Profile

        public var id: ABI.AppIdentifier {
            native.id
        }

        public init(native: Profile) {
            self.native = native
        }
    }

    public struct AppModule: Identifiable, Sendable {
        public let native: Module

        public var id: ABI.AppIdentifier {
            native.id
        }

        public init(native: Module) {
            self.native = native
        }
    }
}
