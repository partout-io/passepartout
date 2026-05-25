// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import Partout

extension ABI {
    public struct ExperimentalPreferences: Hashable, Codable, Sendable {
        public var ignoredConfigFlags: Set<ABI.ConfigFlag> = []
        public var enabledConfigFlags: Set<ABI.ConfigFlag> = []
    }

    public protocol AppPreferencesProtocol {
        var configFlags: Set<ConfigFlag> { get set }
        var deviceId: String { get set }
        var dnsFallsBack: Bool { get set }
        var experimental: ExperimentalPreferences { get set }
        var extensiveLogging: Bool { get set }
        var lastCheckedVersionDate: TimeInterval? { get set }
        var lastCheckedVersion: String? { get set }
        var lastUsedProfileId: Profile.ID? { get set }
        var logsPrivateData: Bool { get set }
        var newProfileEncoding: Bool { get set }
        var relaxedVerification: Bool { get set }
        var skipsPurchases: Bool { get set }
    }
}
