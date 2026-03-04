// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import Partout

extension ABI {
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
