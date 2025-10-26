// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import Foundation

@MainActor
public final class GitHubReleaseStrategy: VersionCheckerStrategy {
    private let releaseURL: URL

    private let rateLimit: TimeInterval

    public init(releaseURL: URL, rateLimit: TimeInterval) {
        self.releaseURL = releaseURL
        self.rateLimit = rateLimit
    }

    public func latestVersion(since: Date) async throws -> SemanticVersion {
        if since > .distantPast {
            let elapsed = -since.timeIntervalSinceNow
            guard elapsed >= rateLimit else {
                pp_log_g(.app, .debug, "Version (GitHub): elapsed \(elapsed) < \(rateLimit)")
                throw AppError.rateLimit
            }
        }

        var request = URLRequest(url: releaseURL)
        request.cachePolicy = .useProtocolCachePolicy
        let result = try await URLSession.shared.data(for: request)

        let json = try JSONDecoder().decode(VersionJSON.self, from: result.0)
        let newVersion = json.name
        guard let semNew = SemanticVersion(newVersion) else {
            pp_log_g(.app, .error, "Version (GitHub): unparsable release name '\(newVersion)'")
            throw AppError.unexpectedResponse
        }
        return semNew
    }
}

private struct VersionJSON: Decodable, Sendable {
    enum CodingKeys: String, CodingKey {
        case name

        case tagName = "tag_name"
    }

    let name: String

    let tagName: String
}
