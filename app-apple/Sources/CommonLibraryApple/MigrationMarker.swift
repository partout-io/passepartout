// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import Foundation

public final class MigrationMarker: @unchecked Sendable {
    public enum Key: String {
        case didMigrateDeveloperIDManagers

        var defaultsKey: String {
            "Migrations.\(rawValue)"
        }
    }

    private let defaults: UserDefaults

    public init(defaults: UserDefaults) {
        self.defaults = defaults
    }

    public func isComplete(_ key: Key) -> Bool {
        defaults.bool(forKey: key.defaultsKey)
    }

    public func markComplete(_ key: Key) {
        defaults.set(true, forKey: key.defaultsKey)
    }
}
