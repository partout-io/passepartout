// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonLibrary
import Observation

@MainActor @Observable
public final class ViewLogger: AppLogger {
    private let logger: AppLogger

    public init(logger: AppLogger) {
        self.logger = logger
    }

    public func log(_ category: ABI.AppLogCategory, _ level: ABI.AppLogLevel, _ message: String) {
        logger.log(category, level, message)
    }

    public func formattedLog(timestamp: Date, message: String) -> String {
        logger.formattedLog(timestamp: timestamp, message: message)
    }
}
