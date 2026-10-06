// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import Foundation
import Partout
import Testing

struct AppPreferencesTests {
    @Test(arguments: ["daemonLooperV2", "daemonLooperV2WireGuard"])
    func givenLegacyDaemonKey_thenDoesNotEnableDaemonFeatures(key: String) throws {
        let data = try JSONEncoder().encode(key)
        let flag = try ABI.decode(ABI.ConfigFlag.self, from: data)
        #expect(flag == .unknown)
        #expect(Set([flag]).daemonFeatureFlags.isEmpty)
    }

    @Test
    func givenDaemonConfigFlags_thenSelectsDaemonFeatures() {
        let cases: [(Set<ABI.ConfigFlag>, Set<DaemonFeatureFlag>)] = [
            ([], []),
            ([.appNotWorking], []),
            ([.experimentalDaemon_202610], [.experimentalDaemon]),
            ([.experimentalDaemonOpenVPN_202610], [.experimentalOpenVPN]),
            ([.experimentalDaemonWireGuard_202610], [.experimentalWireGuard]),
            ([.experimentalDaemon_202610, .experimentalDaemonOpenVPN_202610], [.experimentalDaemon, .experimentalOpenVPN]),
            ([.experimentalDaemon_202610, .experimentalDaemonWireGuard_202610], [.experimentalDaemon, .experimentalWireGuard]),
            ([.experimentalDaemon_202610, .experimentalDaemonOpenVPN_202610, .experimentalDaemonWireGuard_202610], [.experimentalDaemon, .experimentalOpenVPN, .experimentalWireGuard])
        ]
        for (flags, expected) in cases {
            #expect(flags.daemonFeatureFlags == expected)
        }
    }

    @Test
    func givenDaemonConfigOverrides_thenSelectsEffectiveDaemonFeatures() {
        var sut: ABI.AppPreferences = .default()
        sut.configFlags = [.experimentalDaemon_202610, .experimentalDaemonOpenVPN_202610, .experimentalDaemonWireGuard_202610]
        sut.experimental.ignoredConfigFlags = [.experimentalDaemonWireGuard_202610]
        #expect(sut.enabledFlags().daemonFeatureFlags == [.experimentalDaemon, .experimentalOpenVPN])

        sut.experimental.ignoredConfigFlags = [.experimentalDaemon_202610]
        #expect(sut.enabledFlags().daemonFeatureFlags == [.experimentalOpenVPN, .experimentalWireGuard])

        sut.configFlags = []
        sut.experimental.enabledConfigFlags = [.experimentalDaemonWireGuard_202610]
        #expect(sut.enabledFlags().daemonFeatureFlags == [.experimentalWireGuard])
    }

    @Test
    func givenAppPreferencesProtocol_whenSerialized_thenPreservesValues() {
        let expected = Self.preferences()
        let sut: any ABI.AppPreferencesProtocol = expected

        #expect(sut.serialized() == expected)
    }

    @Test
    func givenUserDefaultsAppPreferences_whenCopy_thenPreservesValues() throws {
        let expected = Self.preferences()
        let suiteName = "AppPreferenceTests.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        defer {
            defaults.removePersistentDomain(forName: suiteName)
        }

        let sut = UserDefaultsAppPreferences(defaults: defaults)
        sut.copy(expected)

        #expect(sut.configFlags == expected.configFlags)
        #expect(sut.deviceId == expected.deviceId)
        #expect(sut.dnsFallsBack == expected.dnsFallsBack)
        #expect(sut.experimental == expected.experimental)
        #expect(sut.extensiveLogging == expected.extensiveLogging)
        #expect(sut.lastCheckedVersionDate?.timestamp == expected.lastCheckedVersionDate?.timestamp)
        #expect(sut.lastCheckedVersion == expected.lastCheckedVersion)
        #expect(sut.lastUsedProfileId == expected.lastUsedProfileId)
        #expect(sut.logsPrivateData == expected.logsPrivateData)
        #expect(sut.skipsPurchases == expected.skipsPurchases)
    }

    @Test
    func givenExperimental_whenIgnoreFlags_thenIsApplied() {
        var sut: ABI.AppPreferences = .default()
        sut.configFlags = [.unknown, .appNotWorking]
        sut.experimental.ignoredConfigFlags = [.unknown]
        #expect(sut.isFlagEnabled(.appNotWorking))
        #expect(!sut.isFlagEnabled(.unknown))
    }

    @Test
    func givenExperimental_whenDecodeWithoutEnabledFlags_thenUsesEmptySet() throws {
        let data = Data(#"{"ignoredConfigFlags":["sdfgasdfasdg"]}"#.utf8)
        let sut = try ABI.decode(ABI.ExperimentalPreferences.self, from: data)
        #expect(sut.ignoredConfigFlags == [.unknown])
        #expect(sut.enabledConfigFlags.isEmpty)
    }

    @Test
    func givenExperimental_whenEnableFlags_thenIsApplied() {
        var sut: ABI.AppPreferences = .default()
        sut.configFlags = [.unknown]
        sut.experimental.enabledConfigFlags = [.appNotWorking]

        #expect(sut.isFlagEnabled(.unknown))
        #expect(sut.isFlagEnabled(.appNotWorking))
        #expect(sut.enabledFlags() == [.unknown, .appNotWorking])
    }

    @Test
    func givenExperimental_whenEnableAndIgnoreSameFlag_thenIgnoreWins() {
        var sut: ABI.AppPreferences = .default()
        sut.configFlags = [.unknown]
        sut.experimental.ignoredConfigFlags = [.appNotWorking]
        sut.experimental.enabledConfigFlags = [.appNotWorking]

        #expect(!sut.isFlagEnabled(.appNotWorking))
        #expect(sut.enabledFlags() == [.unknown])
    }

    @Test
    func givenProvidedFlags_whenEnableFlags_thenUsesProvidedValues() {
        var sut: ABI.AppPreferences = .default()
        sut.configFlags = [.appNotWorking]

        let remoteFlags: Set<ABI.ConfigFlag> = [.unknown]

        #expect(sut.enabledFlags(of: remoteFlags) == [.unknown])
    }
}

private extension AppPreferencesTests {
    static func preferences() -> ABI.AppPreferences {
        var preferences: ABI.AppPreferences = .default()
        preferences.configFlags = [.unknown, .appNotWorking]
        preferences.deviceId = "DeviceID"
        preferences.dnsFallsBack = false
        preferences.experimental.ignoredConfigFlags = [.appNotWorking]
        preferences.experimental.enabledConfigFlags = [.unknown]
        preferences.extensiveLogging = true
        preferences.lastCheckedVersionDate = Date(timeIntervalSince1970: 1_746_626_400.123)
        preferences.lastCheckedVersion = "4.10.20"
        preferences.lastUsedProfileId = Profile.ID(uuidString: "00000000-0000-0000-0000-000000000001")!
        preferences.logsPrivateData = true
        preferences.skipsPurchases = true
        return preferences
    }
}
