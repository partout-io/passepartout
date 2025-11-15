// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonLibrary
import Observation

@Observable
public final class ViewLogger: AppLogger {
    private let strategy: AppLogger

    public init(strategy: AppLogger) {
        self.strategy = strategy
    }

    public func log(_ category: AppLogCategory, _ level: AppLogLevel, _ message: String) {
        strategy.log(category, level, message)
    }
}
