// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import Foundation

public final class UserDefaultsStore: KeyValueStore {
    private let defaults: UserDefaults

    public init(_ defaults: UserDefaults) {
        self.defaults = defaults
    }

    public func value<V>(for key: String) -> V? {
        defaults.object(forKey: key) as? V
    }

    public func set<V>(_ value: V?, for key: String) {
        guard let value else {
            defaults.removeObject(forKey: key)
            return
        }
        defaults.set(value, forKey: key)
    }

    public func removeValue(for key: String) {
        defaults.removeObject(forKey: key)
    }
}
