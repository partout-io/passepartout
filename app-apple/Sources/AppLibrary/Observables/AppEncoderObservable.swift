// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonLibrary
import MiniFoundation
import Observation

@MainActor @Observable
public final class AppEncoderObservable {
    private let abi: AppABIProtocol

    public init(abi: AppABIProtocol) {
        self.abi = abi
    }

    public func profile(fromString string: String) throws -> ABI.AppProfile {
        try abi.encoderProfile(fromString: string)
    }

    public func json(fromProfile profile: ABI.AppProfile) throws -> String {
        try abi.encoderJSON(fromProfile: profile)
    }

    public func defaultFilename(for profile: ABI.AppProfile) -> String {
        abi.encoderDefaultFilename(for: profile)
    }

    public func writeToURL(_ profile: ABI.AppProfile) throws -> URL {
        let path = try abi.encoderWriteToFile(profile)
        // Make sure to convert to URL to share actual file content
        return URL(fileURLWithPath: path)
    }
}
