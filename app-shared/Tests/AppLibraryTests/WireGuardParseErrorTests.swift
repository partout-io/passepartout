// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonLibrary
import XCTest

final class WireGuardParseErrorTests: XCTestCase {
    func test_givenLocalizable_whenParseError_thenReturnsLocalizedString() {
        let sut = WireGuardParseError.noInterface
        XCTAssertEqual(sut.localizedDescription, "Configuration must have an ‘Interface’ section.")
    }
}
