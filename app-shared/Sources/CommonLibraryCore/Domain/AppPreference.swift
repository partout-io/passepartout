// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import Partout

extension ABI {
    public enum AppPreference: String, PreferenceProtocol {

        // Not directly accessible
        case deviceId
        case configFlags

        // Manual
        case dnsFallsBack
        //    case dnsFallbackServers
        case lastCheckedVersionDate
        case lastCheckedVersion
        case lastUsedProfileId
        case logsPrivateData
        case relaxedVerification // Though appears in "Experimental"
        case skipsPurchases

        // Experimental
        case experimental

        public var key: String {
            "App.\(rawValue)"
        }
    }
}

// WARNING: Field types must be scalar to fit UserDefaults
extension ABI {
    public struct AppPreferenceValues: Hashable, Codable, Sendable {

        // Override config flags only if non-nil
        public struct Experimental: Hashable, Codable, Sendable {
            public var ignoredConfigFlags: Set<ConfigFlag> = []
        }

        public var deviceId: String?
        // XXX: These are copied from ConfigManager.activeFlags for use
        // in the PacketTunnelProvider (see AppContext.onApplicationActive).
        // In the app, use ConfigManager.activeFlags directly.
        public var configFlagsData: Data?

        public var dnsFallsBack = true
        public var lastCheckedVersionDate: TimeInterval?
        public var lastCheckedVersion: String?
        public var lastUsedProfileId: Profile.ID?
        public var logsPrivateData = false
        public var relaxedVerification = false
        public var skipsPurchases = false

        public var experimentalData: Data?

        public init() {
        }
    }
}

extension ABI.AppPreferenceValues {
    public var configFlags: Set<ABI.ConfigFlag> {
        get {
            guard let configFlagsData else { return [] }
            do {
                return try JSONDecoder().decode(Set<ABI.ConfigFlag>.self, from: configFlagsData)
            } catch {
                pp_log_g(.App.core, .error, "Unable to decode config flags: \(error)")
                return []
            }
        }
        set {
            do {
                configFlagsData = try JSONEncoder().encode(newValue)
            } catch {
                pp_log_g(.App.core, .error, "Unable to encode config flags: \(error)")
            }
        }
    }
}

extension ABI.AppPreferenceValues {
    public var experimental: Experimental {
        get {
            guard let experimentalData else { return Experimental() }
            do {
                return try JSONDecoder().decode(Experimental.self, from: experimentalData)
            } catch {
                pp_log_g(.App.core, .error, "Unable to decode experimental: \(error)")
                return Experimental()
            }
        }
        set {
            do {
                experimentalData = try JSONEncoder().encode(newValue)
            } catch {
                pp_log_g(.App.core, .error, "Unable to encode experimental: \(error)")
            }
        }
    }

    public func isFlagEnabled(_ flag: ABI.ConfigFlag) -> Bool {
        configFlags.contains(flag) && !experimental.ignoredConfigFlags.contains(flag)
    }

    public func enabledFlags(of flags: Set<ABI.ConfigFlag>) -> Set<ABI.ConfigFlag> {
        flags.subtracting(experimental.ignoredConfigFlags)
    }
}
