// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonLibrary
import Observation

@MainActor @Observable
public final class ViewLogger: AppLogger, LogFormatter {
    private let logger: AppLogger
    private let formatter: LogFormatter

    public init(logger: AppLogger, formatter: LogFormatter) {
        self.logger = logger
        self.formatter = formatter
    }

    public func log(_ category: ABI.AppLogCategory, _ level: ABI.AppLogLevel, _ message: String) {
        logger.log(category, level, message)
    }

    public nonisolated func flushLogs() {
        logger.flushLogs()
    }

    public func formattedLog(timestamp: Date, message: String) -> String {
        formatter.formattedLog(timestamp: timestamp, message: message)
    }
}
