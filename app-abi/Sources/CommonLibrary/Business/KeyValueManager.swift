// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonUtils
import Foundation

// FIXME: ###, Keep MainActor until observers
@MainActor
public final class KeyValueManager: ObservableObject {
    private var store: KeyValueStore

    private let fallback: [String: Any]

    public init(store: KeyValueStore = InMemoryStore(), fallback: [String: Any] = [:]) {
        self.store = store
        self.fallback = fallback
    }

    public func contains(_ key: String) -> Bool {
        store.value(for: key) != nil
    }

    public func object<T>(forKey key: String) -> T? {
        store.value(for: key) ?? fallback[key] as? T
    }

    public func set<T>(_ value: T?, forKey key: String) {
        store.set(value, for: key)
    }

    public func removeObject(forKey key: String) {
        store.removeValue(for: key)
    }

    public subscript<T>(_ key: String) -> T? {
        get {
            object(forKey: key)
        }
        set {
            set(newValue, forKey: key)
        }
    }
}

extension KeyValueManager {
    public struct InMemoryStore: KeyValueStore {
        private var map: [String: Any]

        public init() {
            map = [:]
        }

        public func value<V>(for key: String) -> V? {
            map[key] as? V
        }

        public mutating func set<V>(_ value: V, for key: String) {
            map[key] = value
        }

        public mutating func removeValue(for key: String) {
            map.removeValue(forKey: key)
        }
    }
}

// MARK: - Shortcuts

extension KeyValueManager {
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
