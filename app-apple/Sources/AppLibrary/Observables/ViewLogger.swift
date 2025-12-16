// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonLibrary
import MiniFoundation
import Observation

@Observable
public final class ViewLogger: AppLogger {
    private let strategy: AppLogger

    public init(strategy: AppLogger) {
        self.strategy = strategy
    }

    public func log(_ category: ABI.AppLogCategory, _ level: ABI.AppLogLevel, _ message: String) {
        strategy.log(category, level, message)
    }

    public func formattedLog(timestamp: Date, message: String) -> String {
        strategy.formattedLog(timestamp: timestamp, message: message)
    }
}
