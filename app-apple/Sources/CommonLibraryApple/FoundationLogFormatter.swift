// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import Partout

public final class FoundationLogFormatter: LogFormatter {
    private let formatter: DateFormatter
    private let messageFormat: String

    public init(dateFormat: String, messageFormat: String) {
        formatter = DateFormatter()
        formatter.dateFormat = dateFormat
        self.messageFormat = messageFormat
    }

    public func formattedLog(timestamp: Date, message: String) -> String {
        let formattedTimestamp = formatter.string(from: timestamp)
        return String(format: messageFormat, formattedTimestamp, message)
    }
}
