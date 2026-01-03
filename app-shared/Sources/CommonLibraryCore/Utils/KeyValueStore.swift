// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

public protocol KeyValueStore: AnyObject, Sendable {
    func strictObject<V>(forKey key: String) -> V?

    func object<V>(forKey key: String, fallback: V?) -> V?

    func set<V>(_ object: V?, forKey key: String)

    func removeObject(forKey key: String)
}

extension KeyValueStore {
    public subscript<V>(_ key: String) -> V? {
        get {
            object(forKey: key, fallback: nil)
        }
        set {
            set(newValue, forKey: key)
        }
    }

    public func object<V>(forKey key: String, fallback: V?) -> V? {
        strictObject(forKey: key) ?? fallback
    }

    public func bool(forKey key: String, fallback: Bool) -> Bool {
        var value = self[key] as Bool?
        return value ?? fallback
    }

    public func integer(forKey key: String, fallback: Int) -> Int {
        var value = self[key] as Int?
        return value ?? fallback
    }

    public func double(forKey key: String, fallback: Double) -> Double {
        var value = self[key] as Double?
        return value ?? fallback
    }

    public func string(forKey key: String, fallback: String?) -> String? {
        var value = self[key] as String?
        return value ?? fallback
    }
}
