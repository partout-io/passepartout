// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

@testable import CommonLibraryCore
import Foundation
import XCTest

final class HTMLTemplateTests: XCTestCase {
    func test_givenTemplate_whenInjectKey_thenReturnsLocalizedHTML() throws {
        let html = """
Hey show some #{web_uploader.success}
"""
        let sut = HTMLTemplate(html: html)
        let localized = sut.withLocalizedKeys(in: .module)
        XCTAssertEqual(localized, "Hey show some Upload complete!")
    }
}
