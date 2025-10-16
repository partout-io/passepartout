// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonLibrary
import Foundation
import Testing

struct AppPreferenceTests {
    @Test
    func givenFlags_whenSet_thenDataMatches() throws {
        var sut = AppPreferenceValues()
        sut.configFlags = [.ovpnCrossConnection, .tvSendTo]
        sut.experimental.ignoredConfigFlags = [.appNotWorking, .neSocketUDP]

        let configFlagsData = try #require(sut.configFlagsData)
        let experimentalData = try #require(sut.experimentalData)
        let configFlags = try JSONDecoder().decode(Set<ConfigFlag>.self, from: configFlagsData)
        let experimental = try JSONDecoder().decode(AppPreferenceValues.Experimental.self, from: experimentalData)
        #expect(configFlags == sut.configFlags)
        #expect(experimental == sut.experimental)
    }

    @Test
    func givenExperimental_whenIgnoreFlags_thenIsApplied() {
        var sut = AppPreferenceValues()
        sut.configFlags = [.tvSendTo, .neSocketUDP]
        sut.experimental.ignoredConfigFlags = [.appNotWorking, .neSocketUDP]
        #expect(sut.isFlagEnabled(.tvSendTo))
        #expect(!sut.isFlagEnabled(.neSocketUDP))
        #expect(!sut.isFlagEnabled(.appNotWorking))
    }
}
