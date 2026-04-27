// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import Partout

public final class AppEncoder: Sendable {
    private let coder: ProfileCoder
    private let kvStore: KeyValueStore

    public init(coder: ProfileCoder, kvStore: KeyValueStore) {
        self.coder = coder
        self.kvStore = kvStore
    }

    public func defaultFilename(for profileName: String) -> String {
        "\(profileName).json"
    }

    public func profile(fromString string: String) throws -> Profile {
        try coder.profile(fromString: string)
    }

    public func string(fromProfile profile: Profile) throws -> String {
        try coder.string(fromProfile: profile)
    }

    public func writeToFile(_ profile: Profile) throws -> String {
        let string = try string(fromProfile: profile)
        let data = Data(string.utf8)
        let filename = "\(profile.id.uuidString).json"
        let path = FileManager.default.makeTemporaryURL(filename: filename).filePath()
        try data.write(toFile: path)
        return path
    }
}
