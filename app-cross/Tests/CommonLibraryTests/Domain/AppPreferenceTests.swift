// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import Partout
import Testing

struct AppPreferenceTests {
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
