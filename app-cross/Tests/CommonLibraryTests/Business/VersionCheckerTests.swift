// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import Partout
import Testing

@MainActor
struct VersionCheckerTests {
    let downloadURL = URL(string: "http://")!

    @Test
    func detectUpdate() async throws {
        let kv = InMemoryStore()
        let sut = VersionChecker(
            kvStore: kv,
            strategy: MockStrategy(),
            currentVersion: "1.2.3",
            downloadURL: downloadURL
        )
        #expect(sut.latestRelease == nil)
        await sut.checkLatestRelease()
        let latest = try #require(sut.latestRelease)
        #expect(latest.url == downloadURL)
        #expect(latest == sut.latestRelease)
        #expect(kv.string(forAppPreference: .lastCheckedVersion) == "4.10.20")
    }

    @Test
    func ignoreUpdateIfUpToDate() async throws {
        let kv = InMemoryStore()
        let sut = VersionChecker(
            kvStore: kv,
            strategy: MockStrategy(),
            currentVersion: "5.0.0",
            downloadURL: downloadURL
        )
        #expect(sut.latestRelease == nil)
        await sut.checkLatestRelease()
        let latest = sut.latestRelease
        #expect(latest == nil)
        #expect(sut.latestRelease == nil)
    }

    @Test
    func triggerRateLimitOnMultipleChecks() async throws {
        let kv = InMemoryStore()
        let strategy = MockStrategy()
        let sut = VersionChecker(
            kvStore: kv,
            strategy: strategy,
            currentVersion: "5.0.0",
            downloadURL: downloadURL
        )
        #expect(sut.latestRelease == nil)

        var lastChecked = kv.double(forAppPreference: .lastCheckedVersionDate)
        #expect(lastChecked == 0.0)

        _ = await sut.checkLatestRelease()
        lastChecked = kv.double(forAppPreference: .lastCheckedVersionDate)
        #expect(lastChecked > 0.0)
        #expect(!strategy.didHitRateLimit)

        _ = await sut.checkLatestRelease()
        #expect(strategy.didHitRateLimit)
    }
}

private final class MockStrategy: VersionCheckerStrategy, @unchecked Sendable {

    // Only allow once
    var didHitRateLimit = false

    func latestVersion(since: Date) async throws -> ABI.SemanticVersion {
        if since > .distantPast {
            didHitRateLimit = true
        }
        return ABI.SemanticVersion("4.10.20")!
    }
}
