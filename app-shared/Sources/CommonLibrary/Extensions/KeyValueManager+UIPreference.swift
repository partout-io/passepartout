// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

extension KeyValueManager {
    public func object<T>(forUIPreference pref: ABI.UIPreference) -> T? {
        object(forKey: pref.key)
    }

    public func set<T>(_ value: T?, forUIPreference pref: ABI.UIPreference) {
        set(value, forKey: pref.key)
    }
}

extension KeyValueManager {
    public func bool(forUIPreference pref: ABI.UIPreference) -> Bool {
        bool(forKey: pref.key)
    }

    public func integer(forUIPreference pref: ABI.UIPreference) -> Int {
        integer(forKey: pref.key)
    }

    public func double(forUIPreference pref: ABI.UIPreference) -> Double {
        double(forKey: pref.key)
    }

    public func string(forUIPreference pref: ABI.UIPreference) -> String? {
        string(forKey: pref.key)
    }
}
