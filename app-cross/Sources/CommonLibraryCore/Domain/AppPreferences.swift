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
    public func serialized() -> ABI.AppPreferences {
        ABI.AppPreferences(
            configFlags: configFlags,
            deviceId: deviceId,
            dnsFallsBack: dnsFallsBack,
            experimental: experimental,
            extensiveLogging: extensiveLogging,
            lastCheckedVersionTimestamp: lastCheckedVersionDate?.timestamp,
            lastCheckedVersion: lastCheckedVersion,
            lastUsedProfileUUID: lastUsedProfileId?.uuidString,
            logsPrivateData: logsPrivateData,
            newProfileEncoding: newProfileEncoding,
            relaxedVerification: relaxedVerification,
            skipsPurchases: skipsPurchases
        )
    }
}

extension ABI.AppPreferences {
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
}

extension ABI.ExperimentalPreferences {
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        ignoredConfigFlags = try container.decodeIfPresent([ABI.ConfigFlag].self, forKey: .ignoredConfigFlags) ?? []
        enabledConfigFlags = try container.decodeIfPresent([ABI.ConfigFlag].self, forKey: .enabledConfigFlags) ?? []
    }
}

extension ABI.AppPreferencesProtocol where Self == ABI.AppPreferences {
    public static func `default`() -> ABI.AppPreferences {
        ABI.AppPreferences(
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

// MARK: - Shareable store

public final class AppPreferencesStore: @unchecked Sendable {
    public var p: ABI.AppPreferencesProtocol

    public init(_ p: ABI.AppPreferencesProtocol = .default()) {
        self.p = p
    }

    public func configureDeviceId(length: Int) -> String {
        if let deviceId = p.deviceId {
            pspLog(.core, .info, "Device ID: \(deviceId)")
            return deviceId
        }
        let newId = String.random(count: length)
        p.deviceId = newId
        pspLog(.core, .info, "Device ID (new): \(newId)")
        return newId
    }
}

// MARK: - Extensions

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

extension ABI.AppPreferences: ABI.AppPreferencesProtocol {
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

extension ABI.ExperimentalPreferences {
    public mutating func ignore(_ flag: ABI.ConfigFlag) {
        guard !ignoredConfigFlags.contains(flag) else { return }
        ignoredConfigFlags.append(flag)
    }

    public mutating func unignore(_ flag: ABI.ConfigFlag) {
        guard ignoredConfigFlags.contains(flag) else { return }
        ignoredConfigFlags.removeAll { $0 == flag }
    }

    public mutating func enable(_ flag: ABI.ConfigFlag) {
        guard !enabledConfigFlags.contains(flag) else { return }
        enabledConfigFlags.append(flag)
    }

    public mutating func disable(_ flag: ABI.ConfigFlag) {
        guard enabledConfigFlags.contains(flag) else { return }
        enabledConfigFlags.removeAll { $0 == flag }
    }
}
