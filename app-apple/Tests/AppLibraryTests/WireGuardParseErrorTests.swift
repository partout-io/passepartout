// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonLibrary
import Testing

struct WireGuardParseErrorTests {
    @Test
    func givenLocalizable_whenParseError_thenReturnsLocalizedString() {
        let sut = WireGuardParseError.noInterface
        #expect(sut.localizedDescription == "Configuration must have an ‘Interface’ section.")
    }
}
