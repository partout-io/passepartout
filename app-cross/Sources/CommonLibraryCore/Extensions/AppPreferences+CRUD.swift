// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import Partout

// MARK: Defaults

extension ABI.AppPreferencesProtocol where Self == ABI.AppPreferences {
    public static func `default`() -> ABI.AppPreferences {
        var preferences = ABI.AppPreferences(
            configFlags: [],
            deviceId: nil,
            dnsFallsBack: true,
            experimental: ABI.ExperimentalPreferences(
                ignoredConfigFlags: [],
                enabledConfigFlags: []
            ),
            extensiveLogging: false,
            lastCheckedVersionTimestamp: nil,
            lastCheckedVersion: nil,
            lastUsedProfileUUID: nil,
            logsPrivateData: false,
            newProfileEncoding: false,
            relaxedVerification: false,
            skipsPurchases: false
        )
        ABI.AppPreferenceKey.allCases.forEach {
            preferences.setDefault(for: $0)
        }
        return preferences
    }

    private mutating func setDefault(for key: ABI.AppPreferenceKey) {
        switch key {
        case .configFlags:
            configFlags = []
        case .deviceId:
            deviceId = nil
        case .dnsFallsBack:
            dnsFallsBack = true
        case .experimental:
            experimental = ABI.ExperimentalPreferences(
                ignoredConfigFlags: [],
                enabledConfigFlags: []
            )
        case .extensiveLogging:
            extensiveLogging = false
        case .lastCheckedVersion:
            lastCheckedVersion = nil
        case .lastCheckedVersionDate:
            lastCheckedVersionDate = nil
        case .lastUsedProfileId:
            lastUsedProfileId = nil
        case .logsPrivateData:
            logsPrivateData = false
        case .newProfileEncoding:
            newProfileEncoding = false
        case .relaxedVerification:
            relaxedVerification = false
        case .skipsPurchases:
            skipsPurchases = false
        }
    }
}

// MARK: - Encoding

extension ABI.AppPreferencesProtocol {
    public func serialized() -> ABI.AppPreferences {
        var preferences = ABI.AppPreferences.default()
        ABI.AppPreferenceKey.allCases.forEach {
            preferences.copy($0, from: self)
        }
        return preferences
    }

    private mutating func copy(_ key: ABI.AppPreferenceKey, from preferences: any ABI.AppPreferencesProtocol) {
        switch key {
        case .configFlags:
            configFlags = preferences.configFlags
        case .deviceId:
            deviceId = preferences.deviceId
        case .dnsFallsBack:
            dnsFallsBack = preferences.dnsFallsBack
        case .experimental:
            experimental = preferences.experimental
        case .extensiveLogging:
            extensiveLogging = preferences.extensiveLogging
        case .lastCheckedVersion:
            lastCheckedVersion = preferences.lastCheckedVersion
        case .lastCheckedVersionDate:
            lastCheckedVersionDate = preferences.lastCheckedVersionDate
        case .lastUsedProfileId:
            lastUsedProfileId = preferences.lastUsedProfileId
        case .logsPrivateData:
            logsPrivateData = preferences.logsPrivateData
        case .newProfileEncoding:
            newProfileEncoding = preferences.newProfileEncoding
        case .relaxedVerification:
            relaxedVerification = preferences.relaxedVerification
        case .skipsPurchases:
            skipsPurchases = preferences.skipsPurchases
        }
    }
}

// MARK: - Decoding

extension ABI.AppPreferences {
    public init(from decoder: any Decoder) throws {
        let def = Self.default()
        var preferences = def
        let container = try decoder.container(keyedBy: CodingKeys.self)
        try ABI.AppPreferenceKey.allCases.forEach {
            try preferences.decode(from: container, defaultingTo: def, for: $0)
        }
        self = preferences
    }

    private mutating func decode(
        from container: KeyedDecodingContainer<CodingKeys>,
        defaultingTo def: ABI.AppPreferences,
        for key: ABI.AppPreferenceKey
    ) throws {
        switch key {
        case .configFlags:
            configFlags = try container.decodeIfPresent([ABI.ConfigFlag].self, forKey: .configFlags) ?? def.configFlags
        case .deviceId:
            deviceId = try container.decodeIfPresent(String.self, forKey: .deviceId)
        case .dnsFallsBack:
            dnsFallsBack = try container.decodeIfPresent(Bool.self, forKey: .dnsFallsBack) ?? def.dnsFallsBack
        case .experimental:
            experimental = try container.decodeIfPresent(ABI.ExperimentalPreferences.self, forKey: .experimental) ?? def.experimental
        case .extensiveLogging:
            extensiveLogging = try container.decodeIfPresent(Bool.self, forKey: .extensiveLogging) ?? def.extensiveLogging
        case .lastCheckedVersion:
            lastCheckedVersion = try container.decodeIfPresent(String.self, forKey: .lastCheckedVersion)
        case .lastCheckedVersionDate:
            lastCheckedVersionTimestamp = try container.decodeIfPresent(Timestamp.self, forKey: .lastCheckedVersionTimestamp)
        case .lastUsedProfileId:
            lastUsedProfileUUID = try container.decodeIfPresent(String.self, forKey: .lastUsedProfileUUID)
        case .logsPrivateData:
            logsPrivateData = try container.decodeIfPresent(Bool.self, forKey: .logsPrivateData) ?? def.logsPrivateData
        case .newProfileEncoding:
            newProfileEncoding = try container.decodeIfPresent(Bool.self, forKey: .newProfileEncoding) ?? def.newProfileEncoding
        case .relaxedVerification:
            relaxedVerification = try container.decodeIfPresent(Bool.self, forKey: .relaxedVerification) ?? def.relaxedVerification
        case .skipsPurchases:
            skipsPurchases = try container.decodeIfPresent(Bool.self, forKey: .skipsPurchases) ?? def.skipsPurchases
        }
    }
}

extension ABI.ExperimentalPreferences {
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        ignoredConfigFlags = try container.decodeIfPresent([ABI.ConfigFlag].self, forKey: .ignoredConfigFlags) ?? []
        enabledConfigFlags = try container.decodeIfPresent([ABI.ConfigFlag].self, forKey: .enabledConfigFlags) ?? []
    }
}

// MARK: - Editing

// Draft Swift behavior for `psp_preferences_set(const char *json)`.
//
// The OpenAPI root object separates non-destructive updates from destructive
// unsets:
//
// {
//     "values": {
//         "dnsFallsBack": false,
//         "experimental": {
//             "ignoredConfigFlags": ["bsdSockets"],
//             "enabledConfigFlags": []
//         }
//     },
//     "fieldsToUnset": ["deviceId", "lastCheckedVersionDate"]
// }
//
// Semantics:
//
// - Non-null fields in `values` set preferences.
// - Missing or null fields in `values` are ignored.
// - `fieldsToUnset` is the only way to clear optional preferences or reset
//   non-optional preferences to defaults.

private let defaultPreferences = ABI.AppPreferences.default()

extension ABI.AppPreferencesProtocol {
    public mutating func apply(_ patch: ABI.AppPreferencesPatch) {
        if let values = patch.values {
            apply(values)
        }
        patch.fieldsToUnset?.forEach {
            unset($0)
        }
    }

    public mutating func apply(_ values: ABI.AppPreferencesPatchValues) {
        ABI.AppPreferenceKey.allCases.forEach {
            apply(values, for: $0)
        }
    }

    private mutating func apply(_ values: ABI.AppPreferencesPatchValues, for key: ABI.AppPreferenceKey) {
        switch key {
        case .configFlags:
            if let value = values.configFlags {
                configFlags = value
            }
        case .deviceId:
            if let value = values.deviceId {
                deviceId = value
            }
        case .dnsFallsBack:
            if let value = values.dnsFallsBack {
                dnsFallsBack = value
            }
        case .experimental:
            if let value = values.experimental {
                experimental = value
            }
        case .extensiveLogging:
            if let value = values.extensiveLogging {
                extensiveLogging = value
            }
        case .lastCheckedVersion:
            if let value = values.lastCheckedVersion {
                lastCheckedVersion = value
            }
        case .lastCheckedVersionDate:
            if let value = values.lastCheckedVersionDate {
                lastCheckedVersionDate = value
            }
        case .lastUsedProfileId:
            if let value = values.lastUsedProfileId {
                lastUsedProfileId = value
            }
        case .logsPrivateData:
            if let value = values.logsPrivateData {
                logsPrivateData = value
            }
        case .newProfileEncoding:
            if let value = values.newProfileEncoding {
                newProfileEncoding = value
            }
        case .relaxedVerification:
            if let value = values.relaxedVerification {
                relaxedVerification = value
            }
        case .skipsPurchases:
            if let value = values.skipsPurchases {
                skipsPurchases = value
            }
        }
    }

    public mutating func unset(_ key: ABI.AppPreferenceKey) {
        let def = defaultPreferences
        switch key {
        case .configFlags:
            configFlags = def.configFlags
        case .deviceId:
            deviceId = nil
        case .dnsFallsBack:
            dnsFallsBack = def.dnsFallsBack
        case .experimental:
            experimental = def.experimental
        case .extensiveLogging:
            extensiveLogging = def.extensiveLogging
        case .lastCheckedVersion:
            lastCheckedVersion = nil
        case .lastCheckedVersionDate:
            lastCheckedVersionDate = nil
        case .lastUsedProfileId:
            lastUsedProfileId = nil
        case .logsPrivateData:
            logsPrivateData = def.logsPrivateData
        case .newProfileEncoding:
            newProfileEncoding = def.newProfileEncoding
        case .relaxedVerification:
            relaxedVerification = def.relaxedVerification
        case .skipsPurchases:
            skipsPurchases = def.skipsPurchases
        }
    }
}

extension ABI.AppPreferencesPatchValues {
    public var lastCheckedVersionDate: Date? {
        get {
            lastCheckedVersionTimestamp?.date
        }
        set {
            lastCheckedVersionTimestamp = newValue?.timestamp
        }
    }

    public var lastUsedProfileId: Profile.ID? {
        get {
            lastUsedProfileUUID.flatMap {
                Profile.ID(uuidString: $0)
            }
        }
        set {
            lastUsedProfileUUID = newValue?.uuidString
        }
    }
}

extension ABI.AppPreferencesPatch {
    public init(from old: ABI.AppPreferences, to new: ABI.AppPreferences) {
        var values = ABI.AppPreferencesPatchValues()
        var hasValues = false
        var fieldsToUnset: [ABI.AppPreferenceKey] = []

        ABI.AppPreferenceKey.allCases.forEach {
            hasValues = values.setChange(from: old, to: new, for: $0, fieldsToUnset: &fieldsToUnset) || hasValues
        }

        self.init(
            values: hasValues ? values : nil,
            fieldsToUnset: fieldsToUnset.isEmpty ? nil : fieldsToUnset
        )
    }

    public var isEmpty: Bool {
        values == nil && fieldsToUnset == nil
    }
}

private extension ABI.AppPreferencesPatchValues {
    mutating func setChange(
        from old: ABI.AppPreferences,
        to new: ABI.AppPreferences,
        for key: ABI.AppPreferenceKey,
        fieldsToUnset: inout [ABI.AppPreferenceKey]
    ) -> Bool {
        switch key {
        case .configFlags:
            guard old.configFlags != new.configFlags else { return false }
            configFlags = new.configFlags
            return true
        case .deviceId:
            guard old.deviceId != new.deviceId else { return false }
            guard let value = new.deviceId else {
                fieldsToUnset.append(key)
                return false
            }
            deviceId = value
            return true
        case .dnsFallsBack:
            guard old.dnsFallsBack != new.dnsFallsBack else { return false }
            dnsFallsBack = new.dnsFallsBack
            return true
        case .experimental:
            guard old.experimental != new.experimental else { return false }
            experimental = new.experimental
            return true
        case .extensiveLogging:
            guard old.extensiveLogging != new.extensiveLogging else { return false }
            extensiveLogging = new.extensiveLogging
            return true
        case .lastCheckedVersion:
            guard old.lastCheckedVersion != new.lastCheckedVersion else { return false }
            guard let value = new.lastCheckedVersion else {
                fieldsToUnset.append(key)
                return false
            }
            lastCheckedVersion = value
            return true
        case .lastCheckedVersionDate:
            guard old.lastCheckedVersionDate != new.lastCheckedVersionDate else { return false }
            guard let value = new.lastCheckedVersionDate else {
                fieldsToUnset.append(key)
                return false
            }
            lastCheckedVersionDate = value
            return true
        case .lastUsedProfileId:
            guard old.lastUsedProfileId != new.lastUsedProfileId else { return false }
            guard let value = new.lastUsedProfileId else {
                fieldsToUnset.append(key)
                return false
            }
            lastUsedProfileId = value
            return true
        case .logsPrivateData:
            guard old.logsPrivateData != new.logsPrivateData else { return false }
            logsPrivateData = new.logsPrivateData
            return true
        case .newProfileEncoding:
            guard old.newProfileEncoding != new.newProfileEncoding else { return false }
            newProfileEncoding = new.newProfileEncoding
            return true
        case .relaxedVerification:
            guard old.relaxedVerification != new.relaxedVerification else { return false }
            relaxedVerification = new.relaxedVerification
            return true
        case .skipsPurchases:
            guard old.skipsPurchases != new.skipsPurchases else { return false }
            skipsPurchases = new.skipsPurchases
            return true
        }
    }
}
