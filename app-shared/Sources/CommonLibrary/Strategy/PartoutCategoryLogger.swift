// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import Partout

public final class PartoutCategoryLogger: AppLogger {
    private let category: LoggerCategory

    public init(_ category: LoggerCategory) {
        self.category = category
    }

    public func debug(_ message: String) {
        pp_log_g(category, .debug, message)
    }

    public func info(_ message: String) {
        pp_log_g(category, .info, message)
    }

    public func notice(_ message: String) {
        pp_log_g(category, .notice, message)
    }

    public func error(_ message: String) {
        pp_log_g(category, .error, message)
    }
}
