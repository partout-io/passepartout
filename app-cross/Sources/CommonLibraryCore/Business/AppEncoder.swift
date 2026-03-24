// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import Partout

public final class AppEncoder: Sendable {
    private let registry: Registry

    public init(registry: Registry) {
        self.registry = registry
    }

    public func defaultFilename(for profileName: String) -> String {
        "\(profileName).json"
    }

    public func profile(fromString string: String) throws -> Profile {
#if !PSP_CROSS
        try registry.fallbackProfile(fromString: string)
#else
        try registry.profile(fromJSON: string)
#endif
    }

    public func json(fromProfile profile: Profile, withLegacyEncoding: Bool) throws -> String {
        try registry.json(fromProfile: profile, withLegacyEncoding: withLegacyEncoding)
    }

    public func writeToFile(_ profile: Profile, withLegacyEncoding: Bool) throws -> String {
        let json = try json(fromProfile: profile, withLegacyEncoding: withLegacyEncoding)
        let data = Data(json.utf8)
        let filename = "\(profile.id.uuidString).json"
        let path = FileManager.default.makeTemporaryURL(filename: filename).filePath()
        try data.write(toFile: path)
        return path
    }
}
