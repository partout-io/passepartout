// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import Partout

extension ABI {
    public protocol AppPreferencesProtocol: Sendable {
        var configFlags: [ConfigFlag] { get set }
        var deviceId: String? { get set }
        var dnsFallsBack: Bool { get set }
        var experimental: ExperimentalPreferences { get set }
        var extensiveLogging: Bool { get set }
        var lastCheckedVersionDate: Date? { get set }
        var lastCheckedVersion: String? { get set }
        var lastUsedProfileId: Profile.ID? { get set }
        var logsPrivateData: Bool { get set }
        var newProfileEncoding: Bool { get set }
        var relaxedVerification: Bool { get set }
        var skipsPurchases: Bool { get set }
    }
}

extension ABI.AppPreferencesProtocol {
    public func isFlagEnabled(_ flag: ABI.ConfigFlag) -> Bool {
        var result = configFlags.contains(flag)
        result = result || experimental.enabledConfigFlags.contains(flag)
        result = result && !experimental.ignoredConfigFlags.contains(flag)
        return result
    }

    public func enabledFlags(of flags: Set<ABI.ConfigFlag>? = nil) -> Set<ABI.ConfigFlag> {
        var result = flags ?? Set(configFlags)
        result.formUnion(experimental.enabledConfigFlags)
        result.subtract(experimental.ignoredConfigFlags)
        return result
    }
}

extension ABI.AppPreferencesProtocol where Self == ABI.InMemoryAppPreferences {
    public static func `default`() -> ABI.InMemoryAppPreferences {
        ABI.InMemoryAppPreferences(
            configFlags: [],
            deviceId: nil,
            dnsFallsBack: true,
            experimental: ABI.ExperimentalPreferences(
                ignoredConfigFlags: [],
                enabledConfigFlags: []
            ),
            extensiveLogging: false,
            logsPrivateData: false,
            newProfileEncoding: false,
            relaxedVerification: false,
            skipsPurchases: false
        )
    }
}

extension ABI.InMemoryAppPreferences: ABI.AppPreferencesProtocol {
    public init(from decoder: any Decoder) throws {
        let def = Self.default()
        let container = try decoder.container(keyedBy: CodingKeys.self)
        configFlags = try container.decodeIfPresent([ABI.ConfigFlag].self, forKey: .configFlags) ?? def.configFlags
        deviceId = try container.decodeIfPresent(String.self, forKey: .deviceId)
        dnsFallsBack = try container.decodeIfPresent(Bool.self, forKey: CodingKeys.dnsFallsBack) ?? def.dnsFallsBack
        experimental = try container.decodeIfPresent(ABI.ExperimentalPreferences.self, forKey: .experimental) ?? def.experimental
        extensiveLogging = try container.decodeIfPresent(Bool.self, forKey: CodingKeys.extensiveLogging) ?? def.extensiveLogging
        lastCheckedVersionTimestamp = try container.decodeIfPresent(Timestamp.self, forKey: .lastCheckedVersionTimestamp)
        lastCheckedVersion = try container.decodeIfPresent(String.self, forKey: .lastCheckedVersion)
        lastUsedProfileUUID = try container.decodeIfPresent(String.self, forKey: .lastUsedProfileUUID)
        logsPrivateData = try container.decodeIfPresent(Bool.self, forKey: CodingKeys.logsPrivateData) ?? def.logsPrivateData
        newProfileEncoding = try container.decodeIfPresent(Bool.self, forKey: CodingKeys.newProfileEncoding) ?? def.newProfileEncoding
        relaxedVerification = try container.decodeIfPresent(Bool.self, forKey: CodingKeys.relaxedVerification) ?? def.relaxedVerification
        skipsPurchases = try container.decodeIfPresent(Bool.self, forKey: CodingKeys.skipsPurchases) ?? def.skipsPurchases
    }

    public var lastCheckedVersionDate: Date? {
        get {
            lastCheckedVersionTimestamp.flatMap {
                Date(timeIntervalSince1970: Double($0) / 1000.0)
            }
        }
        set {
            lastCheckedVersionTimestamp = newValue.flatMap {
                Timestamp($0.timeIntervalSince1970 * 1000.0)
            }
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

// FIXME: ###, Delete these
extension ABI {
    public typealias AppPreferenceValues = InMemoryAppPreferences
}
extension ABI.AppPreference {
    public var key: String {
        "App.\(rawValue)"
    }
}
