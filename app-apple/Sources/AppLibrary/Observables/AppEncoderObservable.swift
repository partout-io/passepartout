// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonLibrary
import Foundation
import Observation

// Fully non-isolated, no @MainActor here
@Observable
public final class AppEncoderObservable {
    private let appEncoder: AppEncoder

    public init(appEncoder: AppEncoder) {
        self.appEncoder = appEncoder
    }

    public nonisolated func json(fromProfile profile: Profile) throws -> String {
        try appEncoder.string(fromProfile: profile)
    }

    public nonisolated func defaultFilename(for profile: Profile) -> String {
        appEncoder.defaultFilename(for: profile.name)
    }

    public nonisolated func writeToURL(_ profile: Profile) throws -> URL {
        let path = try appEncoder.writeToFile(profile)
        // Make sure to convert to URL to share actual file content
        return URL(fileURLWithPath: path)
    }
}
