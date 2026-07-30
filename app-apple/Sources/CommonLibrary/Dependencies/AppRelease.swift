// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

struct AppRelease: Sendable {
    private let name: String

    fileprivate let build: Int

    init(_ name: String, build: Int) {
        self.name = name
        self.build = build
    }
}

extension ABI.OriginalPurchase {
    func isUntil(_ release: AppRelease) -> Bool {
        buildNumber <= release.build
    }
}
