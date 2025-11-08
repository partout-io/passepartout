// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonUtils
import Foundation

extension KeyValueManager {

    // TODO: #1513, refactor to keep automatically in sync with AppPreference
    public var preferences: AppPreferenceValues {
        get {
            var values = AppPreferenceValues()
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

    public convenience init(store: KeyValueStore, fallback: AppPreferenceValues) {
        let values = [
            AppPreference.dnsFallsBack.key: fallback.dnsFallsBack,
            AppPreference.logsPrivateData.key: fallback.logsPrivateData
        ]
        self.init(store: store, fallback: values)
    }
}

// MARK: - Shortcuts

extension KeyValueManager {
    public func object<T>(forAppPreference pref: AppPreference) -> T? {
        object(forKey: pref.key)
    }

    public func set<T>(_ value: T?, forAppPreference pref: AppPreference) {
        set(value, forKey: pref.key)
    }
}

extension KeyValueManager {
    public func bool(forAppPreference pref: AppPreference) -> Bool {
        bool(forKey: pref.key)
    }

    public func integer(forAppPreference pref: AppPreference) -> Int {
        integer(forKey: pref.key)
    }

    public func double(forAppPreference pref: AppPreference) -> Double {
        double(forKey: pref.key)
    }

    public func string(forAppPreference pref: AppPreference) -> String? {
        string(forKey: pref.key)
    }
}
