// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import AppLibrary
import Testing

final class LocalizationTests {
    @Test
    func givenModules_whenTranslateApp_thenWorks() {
        #expect(Strings.Global.Actions.connect == "Connect")
        #expect(Strings.Global.Nouns.address == "Address")
    }

    @Test
    func givenModules_whenTranslateWireGuard_thenWorks() {
        let sut = WireGuardParseError.noInterface
        #expect(sut.localizedDescription == "Configuration must have an ‘Interface’ section.")
    }
}
