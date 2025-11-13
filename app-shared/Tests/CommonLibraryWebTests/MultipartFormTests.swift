// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonLibraryWeb
import Foundation
import XCTest

final class MultipartFormTests: XCTestCase {
    func test_givenBody_whenParseForm_thenReturnsFields() throws {
        let passcode = "123"
        let fileName = "some-filename.txt"
        let fileContents = "This is the file content"

        let body = """
------WebKitFormBoundaryUtFggDFvBDn88T9z\r
Content-Disposition: form-data; name=\"passcode\"\r
\r
\(passcode)\r
------WebKitFormBoundaryUtFggDFvBDn88T9z\r
Content-Disposition: form-data; name=\"file\"; filename=\"\(fileName)\"\r
Content-Type: application/octet-stream\r
\r
\(fileContents)\r
------WebKitFormBoundaryUtFggDFvBDn88T9z--\r
"""

        let sut = try XCTUnwrap(MultipartForm(body: body))

        XCTAssertNil(sut.fields["passcode"]?.filename)
        XCTAssertEqual(sut.fields["passcode"]?.value, passcode)
        XCTAssertEqual(sut.fields["file"]?.filename, fileName)
        XCTAssertEqual(sut.fields["file"]?.value, fileContents)
    }
}
