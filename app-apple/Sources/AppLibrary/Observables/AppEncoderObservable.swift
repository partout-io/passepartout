// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonLibrary
import Foundation
import Observation

@MainActor @Observable
public final class AppEncoderObservable {
    private let abi: AppABIEncoderProtocol

    public init(abi: AppABIEncoderProtocol) {
        self.abi = abi
    }

    public func profile(fromString string: String) throws -> Profile {
        try abi.profile(fromString: string)
    }

    public func json(fromProfile profile: Profile) throws -> String {
        try abi.json(fromProfile: profile)
    }

    public func defaultFilename(for profile: Profile) -> String {
        abi.defaultFilename(for: profile.name)
    }

    public func writeToURL(_ profile: Profile) throws -> URL {
        let path = try abi.writeToFile(profile)
        // Make sure to convert to URL to share actual file content
        return URL(fileURLWithPath: path)
    }
}
