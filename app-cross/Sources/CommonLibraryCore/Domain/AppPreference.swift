// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import Partout

extension ABI {
    public protocol AppPreferencesProtocol {
        var configFlags: [ConfigFlag] { get set }
        var deviceId: String { get set }
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

extension ABI.InMemoryAppPreferences: ABI.AppPreferencesProtocol {
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

    // FIXME: ###, Centralize defaults
    init() {
        configFlags = []
        deviceId = ""
        dnsFallsBack = true
        experimental = ABI.ExperimentalPreferences(ignoredConfigFlags: [], enabledConfigFlags: [])
        extensiveLogging = false
        logsPrivateData = false
        newProfileEncoding = false
        relaxedVerification = false
        skipsPurchases = false
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
