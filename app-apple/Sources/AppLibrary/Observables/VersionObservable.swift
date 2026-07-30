// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonLibrary
import Observation

@MainActor @Observable
public final class VersionObservable {
    private enum Backend {
        case abi(AppABIVersionProtocol)
        case appConfiguration(ABI.AppConfiguration)
    }

    private let backend: Backend
    public private(set) var latestRelease: ABI.VersionRelease?

    public init(abi: AppABIVersionProtocol) {
        backend = .abi(abi)
        latestRelease = nil
    }

    public init(appConfiguration: ABI.AppConfiguration) {
        backend = .appConfiguration(appConfiguration)
        latestRelease = nil
    }

    public func fetchChangelog(of version: String) async throws -> [ABI.ChangelogEntry] {
        switch backend {
        case .abi(let abi):
            return try await abi.fetchChangelog(of: version)
        case .appConfiguration(let appConfiguration):
            pspLog(.core, .info, "CHANGELOG: Load for version \(version)")
            let url = appConfiguration.constants.github.urlForChangelog(ofVersion: version)
            pspLog(.core, .info, "CHANGELOG: Fetching \(url)")
            do {
                let data = try await appConfiguration.newRequest(
                    for: url,
                    cached: false
                )
                guard let text = String(data: data, encoding: .utf8) else {
                    throw ABI.AppError.notFound
                }
                pspLog(.core, .info, "CHANGELOG: Fetched \(data.count) bytes")
                return text
                    .split(separator: "\n")
                    .enumerated()
                    .compactMap {
                        ABI.ChangelogEntry($0.offset, line: String($0.element))
                    }
            } catch {
                pspLog(.core, .error, "CHANGELOG: Unable to fetch: \(error)")
                throw error
            }
        }
    }

    func onUpdate(_ event: ABI.VersionEvent) {
        switch event {
        case .new(let payload):
            latestRelease = payload.release
        }
    }
}
