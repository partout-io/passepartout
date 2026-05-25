// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import Partout

@BusinessActor
public final class VersionChecker {
    private let preferences: AppPreferencesStore

    private let strategy: VersionCheckerStrategy

    private let currentVersion: ABI.SemanticVersion

    private let downloadURL: URL

    private var isPending = false

    public nonisolated let didChange: PassthroughStream<ABI.VersionEvent>

    public nonisolated init(
        preferences: AppPreferencesStore,
        strategy: VersionCheckerStrategy,
        currentVersion: String,
        downloadURL: URL
    ) {
        guard let semCurrent = ABI.SemanticVersion(currentVersion) else {
            preconditionFailure("Unparsable current version: \(currentVersion)")
        }
        self.preferences = preferences
        self.strategy = strategy
        self.currentVersion = semCurrent
        self.downloadURL = downloadURL
        didChange = PassthroughStream()
    }

    public var latestRelease: ABI.VersionRelease? {
        guard let latestVersionDescription = preferences.p.lastCheckedVersion,
              let latestVersion = ABI.SemanticVersion(latestVersionDescription) else {
            return nil
        }
        return latestVersion > currentVersion ? ABI.VersionRelease(version: latestVersion, url: downloadURL) : nil
    }

    public func checkLatestRelease() async {
        guard !isPending else {
            return
        }
        isPending = true
        defer {
            isPending = false
        }
        let now = Date()
        do {
            let lastCheckedDate = preferences.p.lastCheckedVersionDate ?? .distantPast

            pspLog(.core, .debug, "Version: checking for updates...")
            let fetchedLatestVersion = try await strategy.latestVersion(since: lastCheckedDate)
            preferences.p.lastCheckedVersionDate = now
            preferences.p.lastCheckedVersion = fetchedLatestVersion.description
            pspLog(.core, .info, "Version: \(fetchedLatestVersion) > \(currentVersion) = \(fetchedLatestVersion > currentVersion)")
        } catch ABI.AppError.rateLimit {
            pspLog(.core, .debug, "Version: rate limit")
        } catch ABI.AppError.unexpectedResponse {
            // Save the check date regardless because the service call succeeded
            preferences.p.lastCheckedVersionDate = now

            pspLog(.core, .error, "Unable to check version: \(ABI.AppError.unexpectedResponse)")
        } catch {
            pspLog(.core, .error, "Unable to check version: \(error)")
        }
        guard let latestRelease else {
            pspLog(.core, .debug, "Version: current is latest version")
            return
        }
        pspLog(.core, .info, "Version: new version available at \(latestRelease.url)")
        didChange.send(.new(.init(release: latestRelease)))
    }
}

extension VersionChecker {
    private final class DummyStrategy: VersionCheckerStrategy {
        func latestVersion(since: Date) async throws -> ABI.SemanticVersion {
            ABI.SemanticVersion("255.255.255")!
        }
    }

    public convenience nonisolated init(
        downloadURL: URL = URL(string: "http://")!,
        currentVersion: String = "255.255.255" // An update is never available
    ) {
        self.init(
            preferences: AppPreferencesStore(),
            strategy: DummyStrategy(),
            currentVersion: currentVersion,
            downloadURL: downloadURL
        )
    }
}
