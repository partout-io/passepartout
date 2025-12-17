// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

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
}
