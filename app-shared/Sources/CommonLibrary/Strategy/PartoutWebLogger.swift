// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import Partout

public final class PartoutWebLogger: WebLogger {
    public init() {}

    public func debug(_ message: String) {
        pp_log_g(.App.web, .debug, message)
    }

    public func info(_ message: String) {
        pp_log_g(.App.web, .info, message)
    }

    public func notice(_ message: String) {
        pp_log_g(.App.web, .notice, message)
    }

    public func error(_ message: String) {
        pp_log_g(.App.web, .error, message)
    }
}
