// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonLibrary
import Foundation
import Observation

// Fully non-isolated, no @MainActor here
@Observable
public final class AppEncoderObservable {
    private let abi: AppABIEncoderProtocol

    public init(abi: AppABIEncoderProtocol) {
        self.abi = abi
    }

    public nonisolated func profile(fromString string: String) throws -> Profile {
        try abi.profile(fromString: string)
    }

    public nonisolated func json(fromProfile profile: Profile) throws -> String {
        try abi.json(fromProfile: profile)
    }

    public nonisolated func defaultFilename(for profile: Profile) -> String {
        abi.defaultFilename(for: profile.name)
    }

    public nonisolated func writeToURL(_ profile: Profile) throws -> URL {
        let path = try abi.writeToFile(profile)
        // Make sure to convert to URL to share actual file content
        return URL(fileURLWithPath: path)
    }
}
