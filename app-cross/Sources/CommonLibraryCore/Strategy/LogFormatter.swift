// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import Partout

public protocol LogFormatter: AnyObject, Sendable {
    nonisolated func formattedLog(timestamp: Date, message: String) -> String
}

extension LogFormatter {
    public var localMapper: @Sendable (DebugLog.Line) -> String {
        { [weak self] in
            self?.formattedLog(timestamp: $0.timestamp, message: $0.message) ?? $0.message
        }
    }
}

public final class DummyLogFormatter: LogFormatter {
    public init() {}

    public nonisolated func formattedLog(timestamp: Date, message: String) -> String {
        message
    }
}
