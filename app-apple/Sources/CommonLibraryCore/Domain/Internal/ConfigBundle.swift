// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import Partout

public struct ConfigBundle: Decodable, Sendable {
    public typealias Config = OpenAPIConfigBundleConfig

    // flag -> deployment (0-100)
    public let map: [ABI.ConfigFlag: Config]

    init(map: [ABI.ConfigFlag: Config]) {
        self.map = map
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        map = try container
            .decode([String: Config].self)
            .reduce(into: [:]) {
                guard let flag = ABI.ConfigFlag(rawValue: $1.key) else {
                    return
                }
                $0[flag] = $1.value
            }
    }

    public func activeFlags(withBuild buildNumber: Int) -> Set<ABI.ConfigFlag> {
        let flags = map.filter {
            $0.value.isActive(withBuild: buildNumber)
        }
        return Set(flags.keys)
    }
}

extension ConfigBundle.Config {
    func isActive(withBuild buildNumber: Int) -> Bool {
        guard rate == 100 else {
            return false
        }
        if let minBuild, buildNumber < minBuild {
            return false
        }
        if let platforms {
            return platforms.contains(.apple)
        }
        return true
    }
}
