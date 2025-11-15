// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonLibrary
import Foundation
import XCTest

final class ChangelogTests: XCTestCase {
    func test_givenLine_whenHasIssue_thenParsesEntry() throws {
        let sut = "* Some text (#123)"
        let entry = try XCTUnwrap(ABI.ChangelogEntry(54, line: sut))
        XCTAssertEqual(entry.id, 54)
        XCTAssertEqual(entry.comment, "Some text")
        XCTAssertEqual(entry.issue, 123)
    }

    func test_givenLine_whenHasNoIssue_thenParsesEntry() throws {
        let sut = "* Some text"
        let entry = try XCTUnwrap(ABI.ChangelogEntry(734, line: sut))
        XCTAssertEqual(entry.id, 734)
        XCTAssertEqual(entry.comment, "Some text")
        XCTAssertNil(entry.issue)
    }

    func test_givenLine_whenHasNoIssue_thenReturnsNil() {
        let sut = " fkjndsjkafg"
        XCTAssertNil(ABI.ChangelogEntry(0, line: sut))
    }
}
