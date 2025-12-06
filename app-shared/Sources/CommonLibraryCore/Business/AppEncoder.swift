// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import Partout

public final class AppEncoder: Sendable {
    private let registry: Registry

    public init(registry: Registry) {
        self.registry = registry
    }

    public func defaultFilename(for profile: Profile) -> String {
        "\(profile.name).json"
    }

    public func profile(fromString string: String) throws -> Profile {
#if !PSP_CROSS
        try registry.fallbackProfile(fromString: string)
#else
        try registry.profile(fromJSON: string)
#endif
    }

    public func json(fromProfile profile: Profile) throws -> String {
        try registry.json(fromProfile: profile)
    }

    public func writeToFile(_ profile: Profile) throws -> String {
        let json = try json(fromProfile: profile)
#if !PSP_CROSS
        let data = Data(json.utf8)
#else
        let data = Data([UInt8](json.utf8))
#endif
        let filename = "\(profile.id.uuidString).json"
        let path = FileManager.default.makeTemporaryPath(filename: filename)
        try data.write(toFile: path)
        return path
    }
}
