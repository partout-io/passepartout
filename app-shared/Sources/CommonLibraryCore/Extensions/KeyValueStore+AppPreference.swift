// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

extension KeyValueStore {
    // TODO: #1513, refactor to keep automatically in sync with AppPreference
    public var preferences: ABI.AppPreferenceValues {
        get {
            var values = ABI.AppPreferenceValues()
            values.deviceId = string(forAppPreference: .deviceId)
            values.dnsFallsBack = bool(forAppPreference: .dnsFallsBack)
            values.lastCheckedVersionDate = double(forAppPreference: .lastCheckedVersionDate)
            values.lastCheckedVersion = object(forAppPreference: .lastCheckedVersion)
            values.lastUsedProfileId = object(forAppPreference: .lastUsedProfileId)
            values.logsPrivateData = bool(forAppPreference: .logsPrivateData)
            values.relaxedVerification = bool(forAppPreference: .relaxedVerification)
            values.skipsPurchases = bool(forAppPreference: .skipsPurchases)
            values.configFlagsData = object(forAppPreference: .configFlags)
            values.experimentalData = object(forAppPreference: .experimental)
            return values
        }
        set {
            set(newValue.deviceId, forAppPreference: .dnsFallsBack)
            set(newValue.dnsFallsBack, forAppPreference: .dnsFallsBack)
            set(newValue.lastCheckedVersionDate, forAppPreference: .lastCheckedVersionDate)
            set(newValue.lastCheckedVersion, forAppPreference: .lastCheckedVersion)
            set(newValue.lastUsedProfileId, forAppPreference: .lastUsedProfileId)
            set(newValue.logsPrivateData, forAppPreference: .logsPrivateData)
            set(newValue.relaxedVerification, forAppPreference: .relaxedVerification)
            set(newValue.skipsPurchases, forAppPreference: .skipsPurchases)
            set(newValue.configFlagsData, forAppPreference: .configFlags)
            set(newValue.experimentalData, forAppPreference: .experimental)
        }
    }
}

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
