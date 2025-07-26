// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import Foundation

extension String {
    public var nilIfEmpty: String? {
        !isEmpty ? self : nil
    }

    public var forMenu: String {
#if os(macOS)
        withTrailingDots
#else
        self
#endif
    }

    public var withTrailingDots: String {
        "\(self)..."
    }

    public func trimmedSplit(separator: String) -> [String] {
        split(separator: separator)
            .map {
                $0.trimmingCharacters(in: .whitespaces)
            }
    }
}

extension String {
    private static let alphabet = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz"

    public static func random(count: Int) -> String {
        precondition(count > 0)
        var chars = [Character](repeating: " ", count: count)
        for charIndex in 0..<count {
            let alphabetIndex = alphabet.index(
                alphabet.startIndex,
                offsetBy: .random(in: 0..<alphabet.count)
            )
            let ch = alphabet[alphabetIndex]
            chars[charIndex] = ch
        }
        return String(chars)
    }
}

extension String {
    public var localizedAsRegionCode: String? {
        Locale
            .current
            .localizedString(forRegionCode: self)?
            .capitalized
    }

    public var localizedAsLanguageCode: String? {
        Locale
            .current
            .localizedString(forLanguageCode: self)?
            .capitalized
    }
}

extension String {
    private static let iso8601: ISO8601DateFormatter = {
        let fmt = ISO8601DateFormatter()
        fmt.formatOptions = .withFullDate
        return fmt
    }()

    public var asISO8601Date: Date? {
        Self.iso8601.date(from: self)
    }
}

extension String {
    public var asCountryCodeEmoji: String {
        Self.emoji(forCountryCode: self)
    }

    public static func emoji(forCountryCode countryCode: String) -> String {
        let points = countryCode
            .unicodeScalars
            .compactMap {
                UnicodeScalar(127397 + $0.value)
            }

        return String(String.UnicodeScalarView(points))
    }
}
