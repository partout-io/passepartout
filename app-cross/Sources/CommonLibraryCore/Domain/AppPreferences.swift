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
}

extension ABI.AppPreferencesProtocol {
    public func serialized() -> ABI.AppPreferences {
        var preferences = ABI.AppPreferences.default()
        ABI.AppPreferenceKey.allCases.forEach {
            preferences.copy($0, from: self)
        }
        return preferences
    }
}

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
}

private extension ABI.AppPreferences {
    mutating func copy(_ key: ABI.AppPreferenceKey, from preferences: any ABI.AppPreferencesProtocol) {
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

    mutating func decode(
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

    mutating func setDefault(for key: ABI.AppPreferenceKey) {
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

// MARK: - Shareable store

public final class AppPreferencesStore: @unchecked Sendable {
    public var p: ABI.AppPreferencesProtocol

    public init(_ p: ABI.AppPreferencesProtocol = .default()) {
        self.p = p
    }

    // Read or generate Device ID if needed
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
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        ignoredConfigFlags = try container.decodeIfPresent([ABI.ConfigFlag].self, forKey: .ignoredConfigFlags) ?? []
        enabledConfigFlags = try container.decodeIfPresent([ABI.ConfigFlag].self, forKey: .enabledConfigFlags) ?? []
    }

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
