// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import Partout

public typealias Timestamp = Int64

// Milliseconds since the epoch
extension Timestamp {
    public var date: Date {
        Date(timeIntervalSince1970: TimeInterval(self) / 1000.0)
    }

    public static func now() -> Self {
        Timestamp(Date().timeIntervalSince1970 * 1000.0)
    }
}

extension Date {
    public var timestamp: Timestamp {
        Timestamp(timeIntervalSince1970 * 1000.0)
    }
}
