// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import Foundation
import Partout
import Testing

struct AppPreferencesTests {
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
        sut.configFlags = [.ovpnV3, .zigRuntime]
        sut.experimental.ignoredConfigFlags = [.appNotWorking, .ovpnV3]
        #expect(sut.isFlagEnabled(.zigRuntime))
        #expect(!sut.isFlagEnabled(.ovpnV3))
        #expect(!sut.isFlagEnabled(.appNotWorking))
    }

    @Test
    func givenExperimental_whenDecodeWithoutEnabledFlags_thenUsesEmptySet() throws {
        let data = Data(#"{"ignoredConfigFlags":["ovpnV3"]}"#.utf8)
        let sut = try ABI.decode(ABI.ExperimentalPreferences.self, from: data)
        #expect(sut.ignoredConfigFlags == [.ovpnV3])
        #expect(sut.enabledConfigFlags.isEmpty)
    }

    @Test
    func givenExperimental_whenEnableFlags_thenIsApplied() {
        var sut: ABI.AppPreferences = .default()
        sut.configFlags = [.ovpnV3]
        sut.experimental.enabledConfigFlags = [.zigRuntime]

        #expect(sut.isFlagEnabled(.ovpnV3))
        #expect(sut.isFlagEnabled(.zigRuntime))
        #expect(sut.enabledFlags() == [.ovpnV3, .zigRuntime])
    }

    @Test
    func givenExperimental_whenEnableAndIgnoreSameFlag_thenIgnoreWins() {
        var sut: ABI.AppPreferences = .default()
        sut.configFlags = [.ovpnV3]
        sut.experimental.ignoredConfigFlags = [.zigRuntime]
        sut.experimental.enabledConfigFlags = [.zigRuntime]

        #expect(!sut.isFlagEnabled(.zigRuntime))
        #expect(sut.enabledFlags() == [.ovpnV3])
    }
}

private extension AppPreferencesTests {
    static func preferences() -> ABI.AppPreferences {
        var preferences: ABI.AppPreferences = .default()
        preferences.configFlags = [.ovpnV3, .zigRuntime]
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
