// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

public final class InMemoryStore: KeyValueStore, @unchecked Sendable {
    private var map: [String: Any]

    public let fallback: [String: Any]

    public init(fallback: [String: Any] = [:]) {
        map = [:]
        self.fallback = fallback
    }

    public func contains(_ key: String) -> Bool {
        map[key] != nil
    }

    public func strictObject<V>(forKey key: String) -> V? {
        map[key] as? V
    }

    public func set<V>(_ object: V?, forKey key: String) {
        map[key] = object
    }

    public func removeObject(forKey key: String) {
        map.removeValue(forKey: key)
    }
}
