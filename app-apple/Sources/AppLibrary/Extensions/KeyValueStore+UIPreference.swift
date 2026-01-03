// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonLibrary

extension KeyValueStore {
    func set<V>(_ value: V?, forUIPreference pref: UIPreference) {
        set(value, forKey: pref.key)
    }

    func object<V>(forUIPreference pref: UIPreference, fallback: V? = nil) -> V? {
        object(forKey: pref.key) ?? fallback
    }

    func bool(forUIPreference pref: UIPreference, fallback: Bool = false) -> Bool {
        bool(forKey: pref.key) ?? fallback
    }

    func integer(forUIPreference pref: UIPreference, fallback: Int = 0) -> Int {
        integer(forKey: pref.key) ?? fallback
    }

    func double(forUIPreference pref: UIPreference, fallback: Double = 0.0) -> Double {
        double(forKey: pref.key) ?? fallback
    }

    func string(forUIPreference pref: UIPreference, fallback: String? = nil) -> String? {
        string(forKey: pref.key) ?? fallback
    }
}
