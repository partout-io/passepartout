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
