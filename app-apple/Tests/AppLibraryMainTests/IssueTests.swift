// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

@testable import AppLibraryMain
import CommonLibrary
import Foundation
import Testing

struct IssueTests {
    private let comment = "foobar"

    private let appLine = "Passepartout 1.2.3"

    @Test
    func givenNothing_whenCreateIssue_thenCollectsOSAndDevice() {
        let issue = ABI.Issue(comment: comment, appLine: nil, purchasedProducts: [])
        #expect(issue.appLine == nil)
#if os(iOS)
        #expect(issue.osLine.hasPrefix("iOS"))
#else
        #expect(issue.osLine.hasPrefix("macOS"))
#endif
    }

    @Test
    func givenAppLine_whenCreateIssue_thenCollectsAppLine() {
        let issue = ABI.Issue(comment: comment, appLine: appLine, purchasedProducts: [])
        #expect(issue.appLine == appLine)
    }

    @Test
    func givenAppLineAndProducts_whenCreateIssue_thenMatchesTemplate() {
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
        #expect(issue.body == expected)
    }
}
