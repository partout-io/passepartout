// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonLibrary
import Observation

@MainActor @Observable
public final class VersionObservable {
    private let appConfiguration: ABI.AppConfiguration
    public private(set) var latestRelease: ABI.VersionRelease?

    public init(appConfiguration: ABI.AppConfiguration) {
        self.appConfiguration = appConfiguration
        latestRelease = nil
    }

    public func fetchChangelog(of version: String) async throws -> [ABI.ChangelogEntry] {
        pspLog(.core, .info, "CHANGELOG: Load for version \(version)")
        let url = appConfiguration.constants.github.urlForChangelog(ofVersion: version)
        pspLog(.core, .info, "CHANGELOG: Fetching \(url)")
        do {
            let data = try await appConfiguration.makeRequest(
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

    func onUpdate(_ event: ABI.VersionEvent) {
        switch event {
        case .new(let payload):
            latestRelease = payload.release
        }
    }
}
