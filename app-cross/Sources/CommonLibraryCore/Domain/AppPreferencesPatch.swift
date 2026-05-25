// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import Partout

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

extension AppPreferencesStore {
    public func applyJSON(_ json: String) throws {
        guard let data = json.data(using: .utf8) else {
            throw ABI.AppError.encoding()
        }
        let patch = try ABI.decode(ABI.AppPreferencesPatch.self, from: data)
        apply(patch)
    }

    public func apply(_ patch: ABI.AppPreferencesPatch) {
        p.apply(patch)
    }
}

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
        if let configFlags = values.configFlags {
            self.configFlags = configFlags
        }
        if let deviceId = values.deviceId {
            self.deviceId = deviceId
        }
        if let dnsFallsBack = values.dnsFallsBack {
            self.dnsFallsBack = dnsFallsBack
        }
        if let experimental = values.experimental {
            self.experimental = experimental
        }
        if let extensiveLogging = values.extensiveLogging {
            self.extensiveLogging = extensiveLogging
        }
        if let lastCheckedVersionDate = values.lastCheckedVersionDate {
            self.lastCheckedVersionDate = lastCheckedVersionDate
        }
        if let lastCheckedVersion = values.lastCheckedVersion {
            self.lastCheckedVersion = lastCheckedVersion
        }
        if let lastUsedProfileId = values.lastUsedProfileId {
            self.lastUsedProfileId = lastUsedProfileId
        }
        if let logsPrivateData = values.logsPrivateData {
            self.logsPrivateData = logsPrivateData
        }
        if let newProfileEncoding = values.newProfileEncoding {
            self.newProfileEncoding = newProfileEncoding
        }
        if let relaxedVerification = values.relaxedVerification {
            self.relaxedVerification = relaxedVerification
        }
        if let skipsPurchases = values.skipsPurchases {
            self.skipsPurchases = skipsPurchases
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
