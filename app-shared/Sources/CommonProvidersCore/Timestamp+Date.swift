// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import Foundation

// seconds since the epoch
extension Timestamp {
    public var date: Date {
        Date(timeIntervalSince1970: TimeInterval(self))
    }

    // this can be easily done without Foundation
    public static func now() -> Self {
        UInt32(Date().timeIntervalSince1970)
    }
}

extension Date {
    public var timestamp: Timestamp {
        Timestamp(timeIntervalSince1970)
    }
}
