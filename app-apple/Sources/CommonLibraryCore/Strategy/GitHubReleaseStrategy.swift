// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import Partout

@BusinessActor
public final class GitHubReleaseStrategy: VersionCheckerStrategy {
    private let releaseURL: URL

    private let changelogURL: @Sendable (String) -> URL

    private let rateLimit: TimeInterval

    private let fetcher: @Sendable (URL, Bool) async throws -> Data

    public nonisolated init(
        releaseURL: URL,
        changelogURL: @escaping @Sendable (String) -> URL,
        rateLimit: TimeInterval,
        fetcher: @escaping @Sendable (URL, Bool) async throws -> Data
    ) {
        self.releaseURL = releaseURL
        self.changelogURL = changelogURL
        self.rateLimit = rateLimit
        self.fetcher = fetcher
    }

    public func latestVersion(since: Date) async throws -> ABI.SemanticVersion {
        if since > .distantPast {
            let elapsed = -since.timeIntervalSinceNow
            guard elapsed >= rateLimit else {
                pspLog(.core, .debug, "Version (GitHub): elapsed \(elapsed) < \(rateLimit)")
                throw ABI.AppError.rateLimit
            }
        }
        let data = try await fetcher(releaseURL, true)
        let json = try ABI.decode(VersionJSON.self, from: data)
        let newVersion = json.name
        guard let semNew = ABI.SemanticVersion(newVersion) else {
            pspLog(.core, .error, "Version (GitHub): unparsable release name '\(newVersion)'")
            throw ABI.AppError.unexpectedResponse
        }
        return semNew
    }

    public func fetchChangelog(of version: String) async throws -> [ABI.ChangelogEntry] {
        pspLog(.core, .info, "CHANGELOG: Load for version \(version)")
        let url = changelogURL(version)
        pspLog(.core, .info, "CHANGELOG: Fetching \(url)")
        do {
            let data = try await fetcher(url, false)
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

private extension GitHubReleaseStrategy {
    struct VersionJSON: Decodable, Sendable {
        enum CodingKeys: String, CodingKey {
            case name

            case tagName = "tag_name"
        }

        let name: String

        let tagName: String
    }
}
