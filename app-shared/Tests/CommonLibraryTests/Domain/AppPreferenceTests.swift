// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonLibrary
import Foundation
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
