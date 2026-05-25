// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import Foundation
import Partout
import Testing

struct AppPreferencesTests {
    @Test
    func givenPreferencesProtocol_whenSerialized_thenPreservesValues() {
        let expected = Self.preferences()
        let sut: any ABI.AppPreferencesProtocol = expected

        #expect(sut.serialized() == expected)
    }

    @Test
    func givenUserDefaultsPreferences_whenCopy_thenPreservesValues() throws {
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
        #expect(sut.newProfileEncoding == expected.newProfileEncoding)
        #expect(sut.relaxedVerification == expected.relaxedVerification)
        #expect(sut.skipsPurchases == expected.skipsPurchases)
    }

    @Test
    func givenExperimental_whenIgnoreFlags_thenIsApplied() {
        var sut: ABI.AppPreferences = .default()
        sut.configFlags = [.bsdSockets, .newProfileEncoding]
        sut.experimental.ignoredConfigFlags = [.appNotWorking, .bsdSockets]
        #expect(sut.isFlagEnabled(.newProfileEncoding))
        #expect(!sut.isFlagEnabled(.bsdSockets))
        #expect(!sut.isFlagEnabled(.appNotWorking))
    }

    @Test
    func givenExperimental_whenDecodeWithoutEnabledFlags_thenUsesEmptySet() throws {
        let data = #"{"ignoredConfigFlags":["bsdSockets"]}"#.data(using: .utf8)!
        let sut = try ABI.decode(ABI.ExperimentalPreferences.self, from: data)
        #expect(sut.ignoredConfigFlags == [.bsdSockets])
        #expect(sut.enabledConfigFlags.isEmpty)
    }

    @Test
    func givenExperimental_whenEnableFlags_thenIsApplied() {
        var sut: ABI.AppPreferences = .default()
        sut.configFlags = [.bsdSockets]
        sut.experimental.enabledConfigFlags = [.ovpnCrossV2]

        #expect(sut.isFlagEnabled(.bsdSockets))
        #expect(sut.isFlagEnabled(.ovpnCrossV2))
        #expect(sut.enabledFlags() == [.bsdSockets, .ovpnCrossV2])
    }

    @Test
    func givenExperimental_whenEnableAndIgnoreSameFlag_thenIgnoreWins() {
        var sut: ABI.AppPreferences = .default()
        sut.configFlags = [.bsdSockets]
        sut.experimental.ignoredConfigFlags = [.ovpnCrossV2]
        sut.experimental.enabledConfigFlags = [.ovpnCrossV2]

        #expect(!sut.isFlagEnabled(.ovpnCrossV2))
        #expect(sut.enabledFlags() == [.bsdSockets])
    }
}

private extension AppPreferencesTests {
    static func preferences() -> ABI.AppPreferences {
        var preferences: ABI.AppPreferences = .default()
        preferences.configFlags = [.bsdSockets, .newProfileEncoding]
        preferences.deviceId = "DeviceID"
        preferences.dnsFallsBack = false
        preferences.experimental.ignoredConfigFlags = [.appNotWorking]
        preferences.experimental.enabledConfigFlags = [.ovpnCrossV2]
        preferences.extensiveLogging = true
        preferences.lastCheckedVersionDate = Date(timeIntervalSince1970: 1_746_626_400.123)
        preferences.lastCheckedVersion = "4.10.20"
        preferences.lastUsedProfileId = Profile.ID(uuidString: "00000000-0000-0000-0000-000000000001")!
        preferences.logsPrivateData = true
        preferences.newProfileEncoding = true
        preferences.relaxedVerification = true
        preferences.skipsPurchases = true
        return preferences
    }
}
