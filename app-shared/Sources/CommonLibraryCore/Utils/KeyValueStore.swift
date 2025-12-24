// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

public protocol KeyValueStore: AnyObject {
    var fallback: [String: Any] { get }

    func strictObject<V>(forKey key: String) -> V?

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

    public func object<V>(forKey key: String) -> V? {
        strictObject(forKey: key) ?? fallback[key] as? V
    }

    public func bool(forKey key: String) -> Bool {
        var value = self[key] as Bool?
        if value == nil {
            value = fallback[key] as? Bool
        }
        return value ?? false
    }

    public func integer(forKey key: String) -> Int {
        var value = self[key] as Int?
        if value == nil {
            value = fallback[key] as? Int
        }
        return value ?? 0
    }

    public func double(forKey key: String) -> Double {
        var value = self[key] as Double?
        if value == nil {
            value = fallback[key] as? Double
        }
        return value ?? 0.0
    }

    public func string(forKey key: String) -> String? {
        var value = self[key] as String?
        if value == nil {
            value = fallback[key] as? String
        }
        return value
    }
}
