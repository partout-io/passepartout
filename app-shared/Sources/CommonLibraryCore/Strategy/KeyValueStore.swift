// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

public protocol KeyValueStore: AnyObject, Sendable {
    func object<V>(forKey key: String) -> V?

    func set<V>(_ object: V?, forKey key: String)

    func removeObject(forKey key: String)
}

extension KeyValueStore {
    public subscript<V>(_ key: String) -> V? {
        get {
            object(forKey: key)
        }
        set {
            set(newValue, forKey: key)
        }
    }

    public func bool(forKey key: String) -> Bool? {
        self[key] as Bool?
    }

    public func integer(forKey key: String) -> Int? {
        self[key] as Int?
    }

    public func double(forKey key: String) -> Double? {
        self[key] as Double?
    }

    public func string(forKey key: String) -> String? {
        self[key] as String?
    }
}
