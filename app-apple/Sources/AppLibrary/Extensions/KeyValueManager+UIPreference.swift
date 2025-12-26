// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonLibrary

extension KeyValueStore {
    func set<V>(_ value: V?, forUIPreference pref: UIPreference) {
        set(value, forKey: pref.key)
    }

    func object<V>(forUIPreference pref: UIPreference) -> V? {
        object(forKey: pref.key)
    }

    func bool(forUIPreference pref: UIPreference) -> Bool {
        bool(forKey: pref.key)
    }

    func integer(forUIPreference pref: UIPreference) -> Int {
        integer(forKey: pref.key)
    }

    func double(forUIPreference pref: UIPreference) -> Double {
        double(forKey: pref.key)
    }

    func string(forUIPreference pref: UIPreference) -> String? {
        string(forKey: pref.key)
    }
}
