// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import Foundation

extension Profile {
    public static func sorting(lhs: Self, rhs: Self) -> Bool {
        lhs.name.lowercased() < rhs.name.lowercased()
    }
}

extension Profile {
    public var defaultFilename: String {
        name.appending(".json")
    }

    public func writeToJSON(coder: RegistryCoder) throws -> String {
        try coder.json(from: self)
    }

    public func writeToURL(coder: RegistryCoder) throws -> URL {
        let json = try writeToJSON(coder: coder)
        let data = Data(json.utf8)
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent(id.uuidString)
            .appendingPathExtension("json")
        try data.write(to: url, options: .atomic)
        return url
    }
}
