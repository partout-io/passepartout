// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import Combine

public final class ViewLogger: ObservableObject {
    private let strategy: AppLogger

    public init(strategy: AppLogger) {
        self.strategy = strategy
    }

    public func log(_ category: AppLogCategory, _ level: AppLogLevel, _ message: String) {
        strategy.log(category, level, message)
    }
}
