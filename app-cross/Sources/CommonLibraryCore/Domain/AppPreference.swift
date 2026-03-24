// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import Partout

extension ABI {
    public protocol PreferenceProtocol {
        var key: String { get }
    }

    public enum AppPreference: String, PreferenceProtocol {
        // Not directly accessible
        case deviceId
        case configFlags

        // Manual
        case dnsFallsBack
//        case dnsFallbackServers
        case extensiveLogging
        case lastCheckedVersionDate
        case lastCheckedVersion
        case lastUsedProfileId
        case logsPrivateData
        case newProfileEncoding
        case relaxedVerification // Though appears in "Experimental"
        case skipsPurchases

        // Experimental
        case experimental

        public var key: String {
            "App.\(rawValue)"
        }
    }

    // WARNING: Field types must be scalar to fit UserDefaults
    public struct AppPreferenceValues: Hashable, Codable, Sendable {
        public var deviceId: String?
        public var dnsFallsBack = true
        public var extensiveLogging = false
        public var lastCheckedVersionDate: TimeInterval?
        public var lastCheckedVersion: String?
        public var lastUsedProfileId: Profile.ID?
        public var logsPrivateData = false
        public var newProfileEncoding = false
        public var relaxedVerification = false
        public var skipsPurchases = false

        // XXX: These are copied from ConfigManager.activeFlags for use
        // in the PacketTunnelProvider (see AppABI.onApplicationActive).
        // In the app, use ConfigManager.activeFlags directly.
        public var configFlagsData: Data?

        // Encoded of type Experimental
        public var experimentalData: Data?

        public init() {}

        // TODO: #1513, Error-prone, refactor to keep automatically in sync with AppPreference
        public init(from decoder: any Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            configFlagsData = try container.decodeIfPresent(Data.self, forKey: CodingKeys.configFlagsData)
            deviceId = try container.decodeIfPresent(String.self, forKey: CodingKeys.deviceId)
            dnsFallsBack = try container.decodeIfPresent(Bool.self, forKey: CodingKeys.dnsFallsBack) ?? true
            experimentalData = try container.decodeIfPresent(Data.self, forKey: CodingKeys.experimentalData)
            extensiveLogging = try container.decodeIfPresent(Bool.self, forKey: CodingKeys.extensiveLogging) ?? false
            lastCheckedVersionDate = try container.decodeIfPresent(TimeInterval.self, forKey: CodingKeys.lastCheckedVersionDate)
            lastCheckedVersion = try container.decodeIfPresent(String.self, forKey: CodingKeys.lastCheckedVersion)
            lastUsedProfileId = try container.decodeIfPresent(Profile.ID.self, forKey: CodingKeys.lastUsedProfileId)
            logsPrivateData = try container.decodeIfPresent(Bool.self, forKey: CodingKeys.logsPrivateData) ?? false
            newProfileEncoding = try container.decodeIfPresent(Bool.self, forKey: CodingKeys.newProfileEncoding) ?? false
            relaxedVerification = try container.decodeIfPresent(Bool.self, forKey: CodingKeys.relaxedVerification) ?? false
            skipsPurchases = try container.decodeIfPresent(Bool.self, forKey: CodingKeys.skipsPurchases) ?? false
        }
    }
}

extension ABI.AppPreferenceValues {
    public struct Experimental: Hashable, Codable, Sendable {
        public var ignoredConfigFlags: Set<ABI.ConfigFlag> = []
        public init() {}
    }

    public var configFlags: Set<ABI.ConfigFlag> {
        get {
            guard let configFlagsData else { return [] }
            do {
                return try JSONDecoder().decode(Set<ABI.ConfigFlag>.self, from: configFlagsData)
            } catch {
                pspLog(.core, .error, "Unable to decode config flags: \(error)")
                return []
            }
        }
        set {
            do {
                configFlagsData = try JSONEncoder().encode(newValue)
            } catch {
                pspLog(.core, .error, "Unable to encode config flags: \(error)")
            }
        }
    }

    public var experimental: Experimental {
        get {
            guard let experimentalData else { return Experimental() }
            do {
                return try JSONDecoder().decode(Experimental.self, from: experimentalData)
            } catch {
                pspLog(.core, .error, "Unable to decode experimental: \(error)")
                return Experimental()
            }
        }
        set {
            do {
                experimentalData = try JSONEncoder().encode(newValue)
            } catch {
                pspLog(.core, .error, "Unable to encode experimental: \(error)")
            }
        }
    }

    public func isFlagEnabled(_ flag: ABI.ConfigFlag) -> Bool {
        configFlags.contains(flag) && !experimental.ignoredConfigFlags.contains(flag)
    }

    public func enabledFlags(of flags: Set<ABI.ConfigFlag>? = nil) -> Set<ABI.ConfigFlag> {
        (flags ?? configFlags).subtracting(experimental.ignoredConfigFlags)
    }
}

extension KeyValueStore {
    // TODO: #1513, Error-prone, refactor to keep automatically in sync with AppPreference
    public var preferences: ABI.AppPreferenceValues {
        get {
            var values = ABI.AppPreferenceValues()
            values.configFlagsData = object(forAppPreference: .configFlags)
            values.deviceId = string(forAppPreference: .deviceId)
            values.dnsFallsBack = bool(forAppPreference: .dnsFallsBack, fallback: true)
            values.experimentalData = object(forAppPreference: .experimental)
            values.extensiveLogging = bool(forAppPreference: .extensiveLogging, fallback: false)
            values.lastCheckedVersionDate = double(forAppPreference: .lastCheckedVersionDate)
            values.lastCheckedVersion = object(forAppPreference: .lastCheckedVersion)
            values.lastUsedProfileId = string(forAppPreference: .lastUsedProfileId).flatMap {
                Profile.ID(uuidString: $0)
            }
            values.logsPrivateData = bool(forAppPreference: .logsPrivateData)
            values.newProfileEncoding = bool(forAppPreference: .newProfileEncoding)
            values.relaxedVerification = bool(forAppPreference: .relaxedVerification)
            values.skipsPurchases = bool(forAppPreference: .skipsPurchases)
            return values
        }
        set {
            set(newValue.configFlagsData, forAppPreference: .configFlags)
            set(newValue.deviceId, forAppPreference: .deviceId)
            set(newValue.dnsFallsBack, forAppPreference: .dnsFallsBack)
            set(newValue.experimentalData, forAppPreference: .experimental)
            set(newValue.extensiveLogging, forAppPreference: .extensiveLogging)
            set(newValue.lastCheckedVersionDate, forAppPreference: .lastCheckedVersionDate)
            set(newValue.lastCheckedVersion, forAppPreference: .lastCheckedVersion)
            set(newValue.lastUsedProfileId?.uuidString, forAppPreference: .lastUsedProfileId)
            set(newValue.logsPrivateData, forAppPreference: .logsPrivateData)
            set(newValue.newProfileEncoding, forAppPreference: .newProfileEncoding)
            set(newValue.relaxedVerification, forAppPreference: .relaxedVerification)
            set(newValue.skipsPurchases, forAppPreference: .skipsPurchases)
        }
    }
}
