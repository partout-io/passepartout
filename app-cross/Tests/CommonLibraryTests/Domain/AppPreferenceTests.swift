// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import Partout
import Testing

struct AppPreferenceTests {
    @Test
    func givenFlags_whenSet_thenDataMatches() throws {
        var sut = ABI.AppPreferenceValues()
        sut.configFlags = [.bsdSockets, .newProfileEncoding]
        sut.experimental.ignoredConfigFlags = [.appNotWorking, .bsdSockets]
        sut.experimental.enabledConfigFlags = [.ovpnCrossV2]

        let configFlagsData = try #require(sut.configFlagsData)
        let experimentalData = try #require(sut.experimentalData)
        let configFlags = try JSONDecoder().decode(Set<ABI.ConfigFlag>.self, from: configFlagsData)
        let experimental = try JSONDecoder().decode(ABI.AppPreferenceValues.Experimental.self, from: experimentalData)
        #expect(configFlags == sut.configFlags)
        #expect(experimental == sut.experimental)
    }

    // Value types don't matter to the test
    @Test
    func givenKeyValue_whenSetFallback_thenGetsFallback() {
        let sut = InMemoryStore()
        #expect(sut.bool(forAppPreference: .dnsFallsBack, fallback: true))
        #expect(sut.integer(forAppPreference: .deviceId, fallback: 100) == 100)
        #expect(sut.double(forAppPreference: .lastUsedProfileId, fallback: 200.55) == 200.55)

        sut.set(false, forAppPreference: .dnsFallsBack)
        sut.set(500, forAppPreference: .deviceId)
        sut.set(800.88, forAppPreference: .lastUsedProfileId)
        #expect(!sut.bool(forAppPreference: .dnsFallsBack, fallback: true))
        #expect(sut.integer(forAppPreference: .deviceId, fallback: 100) == 500)
        #expect(sut.double(forAppPreference: .lastUsedProfileId, fallback: 200.55) == 800.88)
    }

    @Test
    func givenExperimental_whenIgnoreFlags_thenIsApplied() {
        var sut = ABI.AppPreferenceValues()
        sut.configFlags = [.bsdSockets, .newProfileEncoding]
        sut.experimental.ignoredConfigFlags = [.appNotWorking, .bsdSockets]
        #expect(sut.isFlagEnabled(.newProfileEncoding))
        #expect(!sut.isFlagEnabled(.bsdSockets))
        #expect(!sut.isFlagEnabled(.appNotWorking))
    }

    @Test
    func givenExperimental_whenDecodeWithoutEnabledFlags_thenUsesEmptySet() throws {
        let data = #"{"ignoredConfigFlags":["bsdSockets"]}"#.data(using: .utf8)!
        let sut = try JSONDecoder().decode(ABI.AppPreferenceValues.Experimental.self, from: data)
        #expect(sut.ignoredConfigFlags == [.bsdSockets])
        #expect(sut.enabledConfigFlags.isEmpty)
    }

    @Test
    func givenExperimental_whenEnableFlags_thenIsApplied() {
        var sut = ABI.AppPreferenceValues()
        sut.configFlags = [.bsdSockets]
        sut.experimental.enabledConfigFlags = [.ovpnCrossV2]

        #expect(sut.isFlagEnabled(.bsdSockets))
        #expect(sut.isFlagEnabled(.ovpnCrossV2))
        #expect(sut.enabledFlags() == [.bsdSockets, .ovpnCrossV2])
    }

    @Test
    func givenExperimental_whenEnableAndIgnoreSameFlag_thenIgnoreWins() {
        var sut = ABI.AppPreferenceValues()
        sut.configFlags = [.bsdSockets]
        sut.experimental.ignoredConfigFlags = [.ovpnCrossV2]
        sut.experimental.enabledConfigFlags = [.ovpnCrossV2]

        #expect(!sut.isFlagEnabled(.ovpnCrossV2))
        #expect(sut.enabledFlags() == [.bsdSockets])
    }
}
