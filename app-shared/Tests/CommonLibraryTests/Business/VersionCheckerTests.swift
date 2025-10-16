// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonLibrary
import Foundation
import Testing

@MainActor
struct VersionCheckerTests {
    let downloadURL = URL(string: "http://")!

    @Test
    func detectUpdate() async throws {
        let kv = KeyValueManager()
        let sut = VersionChecker(
            kvManager: kv,
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
        let kv = KeyValueManager()
        let sut = VersionChecker(
            kvManager: kv,
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
        let kv = KeyValueManager()
        let strategy = MockStrategy()
        let sut = VersionChecker(
            kvManager: kv,
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

private final class MockStrategy: VersionCheckerStrategy {

    // only allow once
    var didHitRateLimit = false

    func latestVersion(since: Date) async throws -> SemanticVersion {
        if since > .distantPast {
            didHitRateLimit = true
        }
        return SemanticVersion("4.10.20")!
    }
}
