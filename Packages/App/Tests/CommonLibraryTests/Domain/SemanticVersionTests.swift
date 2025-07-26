// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonLibrary
import Testing

struct SemanticVersionTests {

    @Test
    func comparison() throws {
        let ref = try #require(SemanticVersion("1.10.10"))
        let newerPatch = try #require(SemanticVersion("1.10.11"))
        let newerPatchOlderMinor = try #require(SemanticVersion("1.9.11"))
        let newerMinorOlderPatch = try #require(SemanticVersion("1.11.0"))
        let newerMajorOlderMinorPatch = try #require(SemanticVersion("2.0.0"))

        #expect(newerPatch > ref)
        #expect(newerPatchOlderMinor < ref)
        #expect(newerMinorOlderPatch > ref)
        #expect(newerMajorOlderMinorPatch > ref)
    }
}
