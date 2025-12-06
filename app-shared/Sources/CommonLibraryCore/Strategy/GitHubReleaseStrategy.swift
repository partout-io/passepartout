// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import Partout

@MainActor
public final class GitHubReleaseStrategy: VersionCheckerStrategy {
    private let releaseURL: URL

    private let rateLimit: TimeInterval

    private let fetcher: @Sendable (URL) async throws -> Data

    public init(
        releaseURL: URL,
        rateLimit: TimeInterval,
        fetcher: @escaping @Sendable (URL) async throws -> Data
    ) {
        self.releaseURL = releaseURL
        self.rateLimit = rateLimit
        self.fetcher = fetcher
    }

    public func latestVersion(since: Date) async throws -> ABI.SemanticVersion {
        if since > .distantPast {
            let elapsed = -since.timeIntervalSinceNow
            guard elapsed >= rateLimit else {
                pp_log_g(.App.core, .debug, "Version (GitHub): elapsed \(elapsed) < \(rateLimit)")
                throw ABI.AppError.rateLimit
            }
        }
        let data = try await fetcher(releaseURL)
        let json = try JSONDecoder().decode(VersionJSON.self, from: data)
        let newVersion = json.name
        guard let semNew = ABI.SemanticVersion(newVersion) else {
            pp_log_g(.App.core, .error, "Version (GitHub): unparsable release name '\(newVersion)'")
            throw ABI.AppError.unexpectedResponse
        }
        return semNew
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
