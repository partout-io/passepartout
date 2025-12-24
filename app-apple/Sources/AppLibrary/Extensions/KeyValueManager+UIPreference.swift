// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonLibrary

extension KeyValueStore {
    public func set<V>(_ value: V?, forUIPreference pref: UIPreference) {
        set(value, forKey: pref.key)
    }

    public func object<V>(forUIPreference pref: UIPreference) -> V? {
        object(forKey: pref.key)
    }

    public func bool(forUIPreference pref: UIPreference) -> Bool {
        bool(forKey: pref.key)
    }

    public func integer(forUIPreference pref: UIPreference) -> Int {
        integer(forKey: pref.key)
    }

    public func double(forUIPreference pref: UIPreference) -> Double {
        double(forKey: pref.key)
    }

    public func string(forUIPreference pref: UIPreference) -> String? {
        string(forKey: pref.key)
    }
}
