// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

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
    nonisolated(unsafe)
    private static let iso8601: ISO8601DateFormatter = {
        let fmt = ISO8601DateFormatter()
        fmt.formatOptions = .withFullDate
        return fmt
    }()

    public var asISO8601Date: Date? {
        Self.iso8601.date(from: self)
    }
}
