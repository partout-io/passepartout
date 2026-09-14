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
}
