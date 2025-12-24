// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

public final class UserDefaultsStore: KeyValueStore {
    private let defaults: UserDefaults

    public let fallback: [String: Any]

    public init(_ defaults: UserDefaults) {
        self.defaults = defaults
        fallback = [:]
    }

    public func strictObject<V>(forKey key: String) -> V? {
        defaults.object(forKey: key) as? V
    }

    public func set<V>(_ object: V?, forKey key: String) {
        guard let object else {
            defaults.removeObject(forKey: key)
            return
        }
        defaults.set(object, forKey: key)
    }

    public func removeObject(forKey key: String) {
        defaults.removeObject(forKey: key)
    }
}
