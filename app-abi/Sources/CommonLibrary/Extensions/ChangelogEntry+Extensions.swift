// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import Foundation

extension ChangelogEntry {
    public var issueURL: URL? {
        issue.map {
            Constants.shared.github.urlForIssue($0)
        }
    }
}

extension ChangelogEntry {
    private static let entryPrefix = "* "

    public init?(_ index: Int, line: String) {
        guard line.hasPrefix(Self.entryPrefix) else {
            return nil
        }
        var comps = line.split(separator: " ")
        comps.removeFirst()

        let optionalIssue: Int?
        if comps.count >= 2, let last = comps.last,
           last.hasPrefix("(#"), last.hasSuffix(")") {
            assert(last.count >= 3)
            let lastString = String(last)
            let start = lastString.index(lastString.startIndex, offsetBy: 2)
            let end = lastString.index(lastString.endIndex, offsetBy: -1)
            let issueString = lastString[start..<end]
            if let issue = Int(issueString) {
                comps.removeLast()
                optionalIssue = issue
            } else {
                optionalIssue = nil
            }
        } else {
            optionalIssue = nil
        }

        self.init(index, comps.joined(separator: " "), optionalIssue)
    }
}
