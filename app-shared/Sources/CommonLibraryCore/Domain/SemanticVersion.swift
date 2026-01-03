// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

extension ABI {
    public struct SemanticVersion: Hashable, Sendable {
        public let major: Int

        public let minor: Int

        public let patch: Int

        public init?(_ string: String) {
            let tokens = string
                .components(separatedBy: ".")
                .compactMap(Int.init)
            guard tokens.count == 3 else {
                return nil
            }
            major = tokens[0]
            minor = tokens[1]
            patch = tokens[2]
        }
    }
}

extension ABI.SemanticVersion: Comparable {
    private var value: Int {
        assert(major <= 0xff)
        assert(minor <= 0xff)
        assert(patch <= 0xff)
        return ((major & 0xff) << 16) + ((minor & 0xff) << 8) + patch
    }

    public static func < (lhs: Self, rhs: Self) -> Bool {
        lhs.value < rhs.value
    }
}

extension ABI.SemanticVersion: CustomStringConvertible {
    public var description: String {
        "\(major).\(minor).\(patch)"
    }
}
