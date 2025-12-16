// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonLibrary
import Testing

struct ChangelogTests {
    @Test
    func givenLine_whenHasIssue_thenParsesEntry() throws {
        let sut = "* Some text (#123)"
        let entry = try #require(ABI.ChangelogEntry(54, line: sut))
        #expect(entry.id == 54)
        #expect(entry.comment == "Some text")
        #expect(entry.issue == 123)
    }

    @Test
    func givenLine_whenHasNoIssue_thenParsesEntry() throws {
        let sut = "* Some text"
        let entry = try #require(ABI.ChangelogEntry(734, line: sut))
        #expect(entry.id == 734)
        #expect(entry.comment == "Some text")
        #expect(entry.issue == nil)
    }

    @Test
    func givenLine_whenHasNoIssue_thenReturnsNil() {
        let sut = " fkjndsjkafg"
        #expect(ABI.ChangelogEntry(0, line: sut) == nil)
    }
}
