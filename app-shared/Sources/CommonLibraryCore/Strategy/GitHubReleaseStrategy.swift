// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import MiniFoundation

@MainActor
public final class GitHubReleaseStrategy: VersionCheckerStrategy {
    private let logger: AppLogger

    private let releaseURL: URL

    private let rateLimit: TimeInterval

    private let fetcher: @Sendable (URL) async throws -> Data

    public init(
        _ logger: AppLogger,
        releaseURL: URL,
        rateLimit: TimeInterval,
        fetcher: @escaping @Sendable (URL) async throws -> Data
    ) {
        self.logger = logger
        self.releaseURL = releaseURL
        self.rateLimit = rateLimit
        self.fetcher = fetcher
    }

    public func latestVersion(since: Date) async throws -> ABI.SemanticVersion {
        if since > .distantPast {
            let elapsed = -since.timeIntervalSinceNow
            guard elapsed >= rateLimit else {
                logger.log(.core, .debug, "Version (GitHub): elapsed \(elapsed) < \(rateLimit)")
                throw ABI.AppError.rateLimit
            }
        }
        let data = try await fetcher(releaseURL)
        let json = try JSONDecoder().decode(VersionJSON.self, from: data)
        let newVersion = json.name
        guard let semNew = ABI.SemanticVersion(newVersion) else {
            logger.log(.core, .error, "Version (GitHub): unparsable release name '\(newVersion)'")
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
