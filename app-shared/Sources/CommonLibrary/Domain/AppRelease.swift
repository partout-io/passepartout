// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

extension ABI {
    public struct AppRelease: Sendable {
        private let name: String

        fileprivate let build: Int

        public init(_ name: String, build: Int) {
            self.name = name
            self.build = build
        }
    }
}

extension OriginalPurchase {
    public func isUntil(_ release: ABI.AppRelease) -> Bool {
        buildNumber <= release.build
    }
}
