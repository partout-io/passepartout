// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import Foundation

struct HTMLTemplate {
    private static let keyPattern: NSRegularExpression = {
        do {
            let pattern = #"#\{([^}]+)\}"#
            return try NSRegularExpression(pattern: pattern)
        } catch {
            fatalError("Unable to create web uploader template regular expression")
        }
    }()

    private let html: String

    init(html: String) {
        self.html = html
    }

    func withLocalizedKeys(in bundle: Bundle) -> String {
        let range = NSRange(html.startIndex..., in: html)
        var result = ""
        var lastRangeEnd = html.startIndex

        Self.keyPattern.enumerateMatches(in: html, range: range) { match, _, _ in
            guard let match = match,
                  let fullRange = Range(match.range(at: 0), in: html),
                  let keyRange = Range(match.range(at: 1), in: html) else {
                return
            }

            result += html[lastRangeEnd..<fullRange.lowerBound]
            let key = String(html[keyRange])
            let localized = bundle.localizedString(forKey: key, value: key, table: "Localizable")

            result += localized
            lastRangeEnd = fullRange.upperBound
        }

        result += html[lastRangeEnd...]
        return result
    }
}
