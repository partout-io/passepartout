// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import Partout

public typealias Timestamp = UInt32

// seconds since the epoch
extension Timestamp {
    public var date: Date {
        Date(timeIntervalSince1970: TimeInterval(self))
    }

    // this can be easily done without Foundation
    public static func now() -> Self {
        Timestamp(Date().timeIntervalSince1970)
    }
}

extension Date {
    public var timestamp: Timestamp {
        Timestamp(timeIntervalSince1970)
    }
}
