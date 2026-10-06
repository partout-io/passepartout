// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import Partout

extension Set where Element == ABI.ConfigFlag {
    public var daemonFeatureFlags: Set<DaemonFeatureFlag> {
        var result: Set<DaemonFeatureFlag> = []
        if contains(.experimentalDaemon_202610) {
            result.insert(.experimentalDaemon)
        }
        if contains(.experimentalDaemonOpenVPN_202610) {
            result.insert(.experimentalOpenVPN)
        }
        if contains(.experimentalDaemonWireGuard_202610) {
            result.insert(.experimentalWireGuard)
        }
        return result
    }
}

extension ABI.ConfigFlag: CustomStringConvertible {
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawValue = try container.decode(String.self)
        guard let known = Self(rawValue: rawValue) else {
            self = .unknown
            return
        }
        self = known
    }

    public var description: String {
        rawValue
    }
}
