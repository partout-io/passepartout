// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

// FIXME: #1594, This is not Sendable, but only used in tests/previews
public final class InMemoryStore: KeyValueStore, @unchecked Sendable {
    private var map: [String: Any]

    public init() {
        map = [:]
    }

    public func contains(_ key: String) -> Bool {
        map[key] != nil
    }

    public func object<V>(forKey key: String) -> V? {
        map[key] as? V
    }

    public func set<V>(_ object: V?, forKey key: String) {
        map[key] = object
    }

    public func removeObject(forKey key: String) {
        map.removeValue(forKey: key)
    }
}
