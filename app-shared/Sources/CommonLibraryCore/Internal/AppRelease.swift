// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

// FIXME: #1594, Make internal
public struct AppRelease: Sendable {
    private let name: String

    fileprivate let build: Int

    public init(_ name: String, build: Int) {
        self.name = name
        self.build = build
    }
}

extension ABI.OriginalPurchase {
    public func isUntil(_ release: AppRelease) -> Bool {
        buildNumber <= release.build
    }
}
