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
        update {
            $0.apply(patch)
        }
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
