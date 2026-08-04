// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import Partout

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
