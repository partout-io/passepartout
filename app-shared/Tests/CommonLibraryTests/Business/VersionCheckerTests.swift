// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import Partout
import Testing

@BusinessActor
struct VersionCheckerTests {
    let downloadURL = URL(string: "http://")!

    @Test
    func detectUpdate() async throws {
        let preferences = AppPreferencesStore()
        let sut = VersionChecker(
            preferences: preferences,
            strategy: MockStrategy(),
            currentVersion: "1.2.3",
            downloadURL: downloadURL
        )
        #expect(sut.latestRelease == nil)
        await sut.checkLatestRelease()
        let latest = try #require(sut.latestRelease)
        #expect(latest.url == downloadURL)
        #expect(latest == sut.latestRelease)
        #expect(preferences[\.lastCheckedVersion] == "4.10.20")
    }

    @Test
    func ignoreUpdateIfUpToDate() async throws {
        let preferences = AppPreferencesStore()
        let sut = VersionChecker(
            preferences: preferences,
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
        let preferences = AppPreferencesStore()
        let strategy = MockStrategy()
        let sut = VersionChecker(
            preferences: preferences,
            strategy: strategy,
            currentVersion: "5.0.0",
            downloadURL: downloadURL
        )
        #expect(sut.latestRelease == nil)

        var lastChecked = preferences[\.lastCheckedVersionDate]
        #expect(lastChecked == nil)

        _ = await sut.checkLatestRelease()
        lastChecked = preferences[\.lastCheckedVersionDate]
        _ = try #require(lastChecked)
        #expect(!strategy.didHitRateLimit)

        _ = await sut.checkLatestRelease()
        #expect(strategy.didHitRateLimit)
    }

    @Test
    func emitCachedUpdateOnRateLimit() async throws {
        var storedPreferences = ABI.AppPreferences.default()
        storedPreferences.lastCheckedVersionDate = Date()
        storedPreferences.lastCheckedVersion = "4.10.20"
        let preferences = AppPreferencesStore(storedPreferences)
        let sut = VersionChecker(
            preferences: preferences,
            strategy: RateLimitedStrategy(),
            currentVersion: "1.2.3",
            downloadURL: downloadURL
        )
        let events = sut.didChange.subscribe()

        async let receivedEvent = firstEvent(in: events)
        await sut.checkLatestRelease()

        let event = try await receivedEvent
        switch event {
        case .new(let payload):
            #expect(payload.release.version == ABI.SemanticVersion("4.10.20"))
            #expect(payload.release.url == downloadURL)
        }
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

private final class RateLimitedStrategy: VersionCheckerStrategy {
    func latestVersion(since: Date) async throws -> ABI.SemanticVersion {
        throw ABI.AppError.rateLimit
    }
}

private enum VersionCheckerTestError: Error {
    case timeout
    case finished
}

private func firstEvent(in stream: AsyncStream<ABI.VersionEvent>) async throws -> ABI.VersionEvent {
    try await withThrowingTaskGroup(of: ABI.VersionEvent?.self) { group in
        group.addTask {
            var iterator = stream.makeAsyncIterator()
            return await iterator.next()
        }
        group.addTask {
            try await Task.sleep(for: .seconds(1))
            throw VersionCheckerTestError.timeout
        }

        guard let event = try await group.next() ?? nil else {
            throw VersionCheckerTestError.finished
        }
        group.cancelAll()
        return event
    }
}
