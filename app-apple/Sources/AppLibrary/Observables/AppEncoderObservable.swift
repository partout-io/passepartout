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

    public func profile(fromString string: String) throws -> ABI.AppProfile {
        try abi.profile(fromString: string)
    }

    public func json(fromProfile profile: ABI.AppProfile) throws -> String {
        try abi.json(fromProfile: profile)
    }

    public func defaultFilename(for profile: ABI.AppProfile) -> String {
        abi.defaultFilename(for: profile)
    }

    public func writeToURL(_ profile: ABI.AppProfile) throws -> URL {
        let path = try abi.writeToFile(profile)
        // Make sure to convert to URL to share actual file content
        return URL(fileURLWithPath: path)
    }
}
