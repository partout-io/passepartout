// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import Foundation
import Testing

@BusinessActor
struct GitHubReleaseStrategyTests {
    @Test
    func usesCacheOnlyForReleaseAndParsesChangelog() async throws {
        let releaseURL = URL(string: "https://example.com/releases/latest")!
        let changelogURL = URL(string: "https://example.com/changelog/4.5.6")!
        let recorder = FetchRecorder(responses: [
            releaseURL: Data(#"{"name":"4.5.6","tag_name":"v4.5.6"}"#.utf8),
            changelogURL: Data("""
            Changelog
            * First fix (#12)
            Not an entry
            * Second fix
            """.utf8)
        ])
        let sut = GitHubReleaseStrategy(
            releaseURL: releaseURL,
            changelogURL: { _ in changelogURL },
            rateLimit: 60,
            fetcher: { url, cached in
                try await recorder.fetch(url, cached: cached)
            }
        )

        let version = try await sut.latestVersion(since: .distantPast)
        let entries = try await sut.fetchChangelog(of: version.description)

        #expect(version == ABI.SemanticVersion("4.5.6"))
        #expect(entries == [
            ABI.ChangelogEntry(id: 1, comment: "First fix", issue: 12),
            ABI.ChangelogEntry(id: 3, comment: "Second fix")
        ])
        #expect(await recorder.requests == [
            .init(url: releaseURL, cached: true),
            .init(url: changelogURL, cached: false)
        ])
    }
}

private actor FetchRecorder {
    struct Request: Equatable, Sendable {
        let url: URL
        let cached: Bool
    }

    private let responses: [URL: Data]
    private(set) var requests: [Request] = []

    init(responses: [URL: Data]) {
        self.responses = responses
    }

    func fetch(_ url: URL, cached: Bool) throws -> Data {
        requests.append(.init(url: url, cached: cached))
        guard let data = responses[url] else {
            throw FetchError.missingResponse
        }
        return data
    }
}

private enum FetchError: Error {
    case missingResponse
}
