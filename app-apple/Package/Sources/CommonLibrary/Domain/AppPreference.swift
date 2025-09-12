// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import Foundation

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

// WARNING: Field types must be scalar to fit UserDefaults
public struct AppPreferenceValues: Hashable, Codable, Sendable {

    // Override config flags only if non-nil
    public struct Experimental: Hashable, Codable, Sendable {
        public var ignoredConfigFlags: Set<ConfigFlag> = []
    }

    public var deviceId: String?
    public var configFlagsData: Data? = nil

    public var dnsFallsBack = true
    public var lastCheckedVersionDate: TimeInterval?
    public var lastCheckedVersion: String?
    public var lastUsedProfileId: Profile.ID?
    public var logsPrivateData = false
    public var relaxedVerification = false
    public var skipsPurchases = false

    public var experimentalData: Data? = nil

    public init() {
    }
}

extension AppPreferenceValues {
    public var configFlags: Set<ConfigFlag> {
        get {
            guard let configFlagsData else { return [] }
            do {
                return try JSONDecoder().decode(Set<ConfigFlag>.self, from: configFlagsData)
            } catch {
                pp_log_g(.app, .error, "Unable to decode config flags: \(error)")
                return []
            }
        }
        set {
            do {
                configFlagsData = try JSONEncoder().encode(newValue)
            } catch {
                pp_log_g(.app, .error, "Unable to encode config flags: \(error)")
            }
        }
    }
}

extension AppPreferenceValues {
    public var experimental: Experimental {
        get {
            guard let experimentalData else { return Experimental() }
            do {
                return try JSONDecoder().decode(Experimental.self, from: experimentalData)
            } catch {
                pp_log_g(.app, .error, "Unable to decode experimental: \(error)")
                return Experimental()
            }
        }
        set {
            do {
                experimentalData = try JSONEncoder().encode(newValue)
            } catch {
                pp_log_g(.app, .error, "Unable to encode experimental: \(error)")
            }
        }
    }

    public func isFlagEnabled(_ flag: ConfigFlag) -> Bool {
        configFlags.contains(flag) && !experimental.ignoredConfigFlags.contains(flag)
    }
}
