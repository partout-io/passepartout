// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonLibrary
import Foundation

@MainActor @Observable
public final class AppEncoderObservable {
    private let encoder: AppEncoder

    public init(encoder: AppEncoder) {
        self.encoder = encoder
    }

    public func profile(fromString string: String) throws -> ABI.AppProfile {
        try ABI.AppProfile(native: encoder.profile(fromString: string))
    }

    public func json(fromProfile profile: ABI.AppProfile) throws -> String {
        try encoder.json(fromProfile: profile.native)
    }

    public func defaultFilename(for profile: ABI.AppProfile) -> String {
        encoder.defaultFilename(for: profile.native)
    }

    public func writeToURL(_ profile: ABI.AppProfile) throws -> URL {
        let path = try encoder.writeToFile(profile.native)
        // Make sure to convert to URL to share actual file content
        return URL(fileURLWithPath: path)
    }
}
