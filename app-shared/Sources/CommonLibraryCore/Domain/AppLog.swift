// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

extension ABI {
    public enum AppLogCategory: String, Identifiable, Sendable {
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

    public struct AppLogLine: Sendable {
        public let timestamp: Date
        public let message: String

        public init(timestamp: Date, message: String) {
            self.timestamp = timestamp
            self.message = message
        }
    }
}
