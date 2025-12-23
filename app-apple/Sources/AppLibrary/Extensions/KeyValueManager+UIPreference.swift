// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonLibrary

extension KeyValueManager {
    public func object<T>(forUIPreference pref: UIPreference) -> T? {
        object(forKey: pref.key)
    }

    public func set<T>(_ value: T?, forUIPreference pref: UIPreference) {
        set(value, forKey: pref.key)
    }
}

extension KeyValueManager {
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
