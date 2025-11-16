// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import Foundation

extension Utils {
    public static func string(fromIPv4 ipv4: UInt32) -> String {
        var remainder = ipv4
        var groups: [UInt32] = []
        var base: UInt32 = 1 << 24
        while base > 0 {
            groups.append(remainder / base)
            remainder %= base
            base >>= 8
        }
        return groups
            .map { $0.description }
            .joined(separator: ".")
    }

    public static func ipv4(fromString string: String) -> UInt32? {
        var addr = in_addr()
        let result = string.withCString {
            inet_pton(AF_INET, $0, &addr)
        }
        guard result > 0 else {
            return nil
        }
        return CFSwapInt32BigToHost(addr.s_addr)
    }
}
