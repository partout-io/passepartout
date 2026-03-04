// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

extension KeyValueStore {
    public func set<V>(_ object: V?, forAppPreference pref: ABI.AppPreference) {
        set(object, forKey: pref.key)
    }

    public func object<V>(forAppPreference pref: ABI.AppPreference) -> V? {
        object(forKey: pref.key)
    }

    public func string(forAppPreference pref: ABI.AppPreference) -> String? {
        string(forKey: pref.key)
    }

    public func bool(forAppPreference pref: ABI.AppPreference, fallback: Bool = false) -> Bool {
        bool(forKey: pref.key) ?? fallback
    }

    public func integer(forAppPreference pref: ABI.AppPreference, fallback: Int = 0) -> Int {
        integer(forKey: pref.key) ?? fallback
    }

    public func double(forAppPreference pref: ABI.AppPreference, fallback: Double = 0.0) -> Double {
        double(forKey: pref.key) ?? fallback
    }
}
