// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import Partout

public protocol LogFormatter: AnyObject, Sendable {
    nonisolated func formattedLog(timestamp: Date, message: String) -> String
}

public final class DummyLogFormatter: LogFormatter {
    public init() {}

    public nonisolated func formattedLog(timestamp: Date, message: String) -> String {
        message
    }
}
