// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import Testing

struct MultipartFormTests {
    @Test
    func givenBody_whenParseForm_thenReturnsFields() throws {
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

        let sut = try #require(MultipartForm(body: body))

        #expect(sut.fields["passcode"]?.filename == nil)
        #expect(sut.fields["passcode"]?.value == passcode)
        #expect(sut.fields["file"]?.filename == fileName)
        #expect(sut.fields["file"]?.value == fileContents)
    }
}
