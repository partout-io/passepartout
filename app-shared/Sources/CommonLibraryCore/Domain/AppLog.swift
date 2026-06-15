// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import Partout

extension ABI {
    public enum AppLogCategory: String, Identifiable, Sendable {
        case abi
        case core
        case iap
        case profiles
        case web

        public var id: String {
            "app.\(rawValue)"
        }
    }

    public enum AppLogLevel {
        case debug
        case info
        case notice
        case error
        case fault
    }

    public struct LogLine: Sendable {
        public let timestamp: Date
        public let message: String

        public init(timestamp: Date, message: String) {
            self.timestamp = timestamp
            self.message = message
        }
    }

    public struct LogEntry: Identifiable, Equatable, Sendable {
        public let date: Date
        public let url: URL
        public var id: Date {
            date
        }

        public init(date: Date, url: URL) {
            self.date = date
            self.url = url
        }
    }
}
