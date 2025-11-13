// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import Foundation
import Partout

private let rfc1123: DateFormatter = {
    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.timeZone = TimeZone(abbreviation: "GMT")
    formatter.dateFormat = "EEE, dd MMM yyyy HH:mm:ss z"
    return formatter
}()

extension Timestamp {
    public func toRFC1123() -> String {
        rfc1123
            .string(from: date)
    }
}

extension String {
    public func fromRFC1123() -> Timestamp? {
        rfc1123
            .date(from: self)
            .map(\.timestamp)
    }
}
