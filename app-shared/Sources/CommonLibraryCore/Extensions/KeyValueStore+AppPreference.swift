// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

extension KeyValueStore {
    public func set<V>(_ object: V?, forAppPreference pref: ABI.AppPreference) {
        set(object, forKey: pref.key)
    }

    public func object<V>(forAppPreference pref: ABI.AppPreference) -> V? {
        object(forKey: pref.key)
    }

    public func bool(forAppPreference pref: ABI.AppPreference) -> Bool {
        bool(forKey: pref.key)
    }

    public func integer(forAppPreference pref: ABI.AppPreference) -> Int {
        integer(forKey: pref.key)
    }

    public func double(forAppPreference pref: ABI.AppPreference) -> Double {
        double(forKey: pref.key)
    }

    public func string(forAppPreference pref: ABI.AppPreference) -> String? {
        string(forKey: pref.key)
    }
}
