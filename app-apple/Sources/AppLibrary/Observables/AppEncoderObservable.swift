// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonLibrary
import Foundation
import Observation

// Fully non-isolated, no @MainActor here
@Observable
public final class AppEncoderObservable {
    private enum Backend: Sendable {
        case abi(AppABIEncoderProtocol)
        case appEncoder(AppEncoder)
    }

    private let backend: Backend

    public init(abi: AppABIEncoderProtocol) {
        backend = .abi(abi)
    }

    public init(appEncoder: AppEncoder) {
        backend = .appEncoder(appEncoder)
    }

    public nonisolated func json(fromProfile profile: Profile) throws -> String {
        switch backend {
        case .abi(let abi):
            return try abi.json(fromProfile: profile)
        case .appEncoder(let appEncoder):
            return try appEncoder.string(fromProfile: profile)
        }
    }

    public nonisolated func defaultFilename(for profile: Profile) -> String {
        switch backend {
        case .abi(let abi):
            return abi.defaultFilename(for: profile.name)
        case .appEncoder(let appEncoder):
            return appEncoder.defaultFilename(for: profile.name)
        }
    }

    public nonisolated func writeToURL(_ profile: Profile) throws -> URL {
        let path: String
        switch backend {
        case .abi(let abi):
            path = try abi.writeToFile(profile)
        case .appEncoder(let appEncoder):
            path = try appEncoder.writeToFile(profile)
        }
        // Make sure to convert to URL to share actual file content
        return URL(fileURLWithPath: path)
    }
}
