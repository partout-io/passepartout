// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

extension ABI {
    public struct AppConfiguration: Decodable, Sendable {
        public let bundle: ABI.AppBundle
        public let constants: ABI.AppConstants

        public init(bundle: ABI.AppBundle, constants: ABI.AppConstants) {
            self.bundle = bundle
            self.constants = constants
        }
    }
}
