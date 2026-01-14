// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import MiniFoundation
import Testing

struct AppPreferenceTests {
    @Test
    func givenFlags_whenSet_thenDataMatches() throws {
        var sut = ABI.AppPreferenceValues()
        sut.configFlags = [.neSocketUDP, .neSocketTCP]
        sut.experimental.ignoredConfigFlags = [.appNotWorking, .neSocketUDP]

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
        sut.configFlags = [.neSocketUDP, .neSocketTCP]
        sut.experimental.ignoredConfigFlags = [.appNotWorking, .neSocketUDP]
        #expect(sut.isFlagEnabled(.neSocketTCP))
        #expect(!sut.isFlagEnabled(.neSocketUDP))
        #expect(!sut.isFlagEnabled(.appNotWorking))
    }
}
