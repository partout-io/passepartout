// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

@testable import AppLibraryMain
import CommonLibrary
import Foundation
import XCTest

final class IssueTests: XCTestCase {
    private let comment = "foobar"

    private let appLine = "Passepartout 1.2.3"

    func test_givenNothing_whenCreateIssue_thenCollectsOSAndDevice() {
        let issue = ABI.Issue(comment: comment, appLine: nil, purchasedProducts: [])
        XCTAssertNil(issue.appLine)
#if os(iOS)
        XCTAssertTrue(issue.osLine.hasPrefix("iOS"))
#else
        XCTAssertTrue(issue.osLine.hasPrefix("macOS"))
#endif
    }

    func test_givenAppLine_whenCreateIssue_thenCollectsAppLine() {
        let issue = ABI.Issue(comment: comment, appLine: appLine, purchasedProducts: [])
        XCTAssertEqual(issue.appLine, appLine)
    }

    func test_givenAppLineAndProducts_whenCreateIssue_thenMatchesTemplate() {
        let issue = ABI.Issue(comment: comment, appLine: appLine, purchasedProducts: [.Features.appleTV])
        let expected = """
Hi,

\(issue.comment)

--

App: \(issue.appLine ?? "unknown")
OS: \(issue.osLine)
Device: \(issue.deviceLine ?? "unknown")
Purchased: ["\(ABI.AppProduct.Features.appleTV.rawValue)"]
Providers: [:]

--

Regards

"""
        XCTAssertEqual(issue.body, expected)
    }
}
