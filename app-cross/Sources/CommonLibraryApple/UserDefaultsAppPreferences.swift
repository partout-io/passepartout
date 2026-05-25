// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import Partout

public final class UserDefaultsAppPreferences: ABI.AppPreferencesProtocol, @unchecked Sendable {
    private let defaults: UserDefaults
    private let fallback: ABI.InMemoryAppPreferences

    public init(defaults: UserDefaults) {
        self.defaults = defaults
        fallback = .default()
    }

    public var configFlags: [ABI.ConfigFlag] {
        get {
            defaults.codableValue(
                [ABI.ConfigFlag].self,
                forAppPreference: .configFlags,
                fallback: fallback.configFlags
            )
        }
        set {
            defaults.setCodableValue(newValue, forAppPreference: .configFlags)
        }
    }

    public var deviceId: String? {
        get {
            defaults.string(forAppPreference: .deviceId)
        }
        set {
            defaults.set(newValue, forAppPreference: .deviceId)
        }
    }

    public var dnsFallsBack: Bool {
        get {
            defaults.bool(forAppPreference: .dnsFallsBack, fallback: fallback.dnsFallsBack)
        }
        set {
            defaults.set(newValue, forAppPreference: .dnsFallsBack)
        }
    }

    public var experimental: ABI.ExperimentalPreferences {
        get {
            defaults.codableValue(
                ABI.ExperimentalPreferences.self,
                forAppPreference: .experimental,
                fallback: fallback.experimental
            )
        }
        set {
            defaults.setCodableValue(newValue, forAppPreference: .experimental)
        }
    }

    public var extensiveLogging: Bool {
        get {
            defaults.bool(forAppPreference: .extensiveLogging, fallback: fallback.extensiveLogging)
        }
        set {
            defaults.set(newValue, forAppPreference: .extensiveLogging)
        }
    }

    public var lastCheckedVersionDate: Date? {
        get {
            defaults.date(forAppPreference: .lastCheckedVersionDate)
        }
        set {
            defaults.set(newValue, forAppPreference: .lastCheckedVersionDate)
        }
    }

    public var lastCheckedVersion: String? {
        get {
            defaults.string(forAppPreference: .lastCheckedVersion)
        }
        set {
            defaults.set(newValue, forAppPreference: .lastCheckedVersion)
        }
    }

    public var lastUsedProfileId: Profile.ID? {
        get {
            defaults
                .string(forAppPreference: .lastUsedProfileId)
                .flatMap(Profile.ID.init(uuidString:))
        }
        set {
            defaults.set(newValue?.uuidString, forAppPreference: .lastUsedProfileId)
        }
    }

    public var logsPrivateData: Bool {
        get {
            defaults.bool(forAppPreference: .logsPrivateData, fallback: fallback.logsPrivateData)
        }
        set {
            defaults.set(newValue, forAppPreference: .logsPrivateData)
        }
    }

    public var newProfileEncoding: Bool {
        get {
            defaults.bool(forAppPreference: .newProfileEncoding, fallback: fallback.newProfileEncoding)
        }
        set {
            defaults.set(newValue, forAppPreference: .newProfileEncoding)
        }
    }

    public var relaxedVerification: Bool {
        get {
            defaults.bool(forAppPreference: .relaxedVerification, fallback: fallback.relaxedVerification)
        }
        set {
            defaults.set(newValue, forAppPreference: .relaxedVerification)
        }
    }

    public var skipsPurchases: Bool {
        get {
            defaults.bool(forAppPreference: .skipsPurchases, fallback: fallback.skipsPurchases)
        }
        set {
            defaults.set(newValue, forAppPreference: .skipsPurchases)
        }
    }
}

private extension UserDefaults {
    func bool(forAppPreference preference: ABI.AppPreference, fallback: Bool) -> Bool {
        let key = preference.key
        guard object(forKey: key) != nil else {
            return fallback
        }
        return bool(forKey: key)
    }

    func date(forAppPreference preference: ABI.AppPreference) -> Date? {
        object(forKey: preference.key) as? Date
    }

    func string(forAppPreference preference: ABI.AppPreference) -> String? {
        string(forKey: preference.key)
    }

    func set(_ value: Bool, forAppPreference preference: ABI.AppPreference) {
        set(value, forKey: preference.key)
    }

    func set(_ value: String?, forAppPreference preference: ABI.AppPreference) {
        let key = preference.key
        guard let value else {
            removeObject(forKey: key)
            return
        }
        set(value, forKey: key)
    }

    func set(_ value: Date?, forAppPreference preference: ABI.AppPreference) {
        let key = preference.key
        guard let value else {
            removeObject(forKey: key)
            return
        }
        set(value, forKey: key)
    }

    func codableValue<T>(
        _ type: T.Type,
        forAppPreference preference: ABI.AppPreference,
        fallback: T
    ) -> T where T: Decodable {
        let key = preference.key
        guard let data = data(forKey: key) else {
            return fallback
        }
        do {
            return try ABI.decode(type, from: data)
        } catch {
            pspLog(.core, .error, "Unable to decode UserDefaults app preference '\(key)': \(error)")
            return fallback
        }
    }

    func setCodableValue<T>(_ value: T, forAppPreference preference: ABI.AppPreference) where T: Encodable {
        let key = preference.key
        do {
            let data = try ABI.encode(value)
            set(data, forKey: key)
        } catch {
            pspLog(.core, .error, "Unable to encode UserDefaults app preference '\(key)': \(error)")
        }
    }
}

private extension ABI.AppPreference {
    var key: String {
        "App.\(rawValue)"
    }
}
