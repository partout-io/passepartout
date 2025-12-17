// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#if canImport(CommonLibraryApple)
@testable import CommonLibraryApple
import Testing

struct HTMLTemplateTests {
    @Test
    func givenTemplate_whenInjectKey_thenReturnsLocalizedHTML() throws {
        let html = """
Hey show some #{web_uploader.success}
"""
        let sut = HTMLTemplate(html: html)
        let localized = sut.withLocalizedKeys(in: .module)
        #expect(localized == "Hey show some Upload complete!")
    }
}
#endif
