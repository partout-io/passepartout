// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import Foundation
import Partout

public final class AppEncoder: ObservableObject {
    private let registry: Registry

    public init(registry: Registry) {
        self.registry = registry
    }

    public func profile(fromString string: String) throws -> Profile {
        try registry.compatibleProfile(fromString: string)
    }

    public func json(fromProfile profile: Profile) throws -> String {
        try registry.json(fromProfile: profile)
    }

    public func defaultFilename(for profile: Profile) -> String {
        profile.name.appending(".json")
    }

    public func writeToJSON(_ profile: Profile) throws -> String {
        try registry.json(fromProfile: profile)
    }

    public func writeToURL(_ profile: Profile) throws -> URL {
        let json = try writeToJSON(profile)
        let data = Data(json.utf8)
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent(profile.id.uuidString)
            .appendingPathExtension("json")
        try data.write(to: url, options: .atomic)
        return url
    }
}
