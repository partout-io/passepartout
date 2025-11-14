// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import Partout

public struct ConfigBundle: Decodable {
    public struct Config: Codable {
        public let rate: Int

        public let minBuild: Int?

        public let data: JSON?

        public func isActive(withBuild buildNumber: Int) -> Bool {
            if let minBuild, buildNumber < minBuild {
                return false
            }
            return rate == 100
        }
    }

    // flag -> deployment (0-100)
    public let map: [ConfigFlag: Config]

    init(map: [ConfigFlag: Config]) {
        self.map = map
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        map = try container
            .decode([String: Config].self)
            .reduce(into: [:]) {
                guard let flag = ConfigFlag(rawValue: $1.key) else {
                    return
                }
                $0[flag] = $1.value
            }
    }

    public func activeFlags(withBuild buildNumber: Int) -> Set<ConfigFlag> {
        let flags = map.filter {
            $0.value.isActive(withBuild: buildNumber)
        }
        return Set(flags.keys)
    }
}
