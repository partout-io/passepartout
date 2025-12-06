// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import Partout

#if !PSP_CROSS
extension VersionChecker: ObservableObject {}
#endif

@MainActor
public final class VersionChecker {
    public struct Release: Hashable, Sendable {
        public let version: ABI.SemanticVersion

        public let url: URL
    }

    private let kvManager: KeyValueManager

    private let strategy: VersionCheckerStrategy

    private let currentVersion: ABI.SemanticVersion

    private let downloadURL: URL

    private var isPending = false

    public init(
        kvManager: KeyValueManager,
        strategy: VersionCheckerStrategy,
        currentVersion: String,
        downloadURL: URL
    ) {
        guard let semCurrent = ABI.SemanticVersion(currentVersion) else {
            preconditionFailure("Unparsable current version: \(currentVersion)")
        }
        self.kvManager = kvManager
        self.strategy = strategy
        self.currentVersion = semCurrent
        self.downloadURL = downloadURL
    }

    public var latestRelease: Release? {
        guard let latestVersionDescription = kvManager.string(forAppPreference: .lastCheckedVersion),
              let latestVersion = ABI.SemanticVersion(latestVersionDescription) else {
            return nil
        }
        return latestVersion > currentVersion ? Release(version: latestVersion, url: downloadURL) : nil
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
            let lastCheckedInterval = kvManager.double(forAppPreference: .lastCheckedVersionDate)
            let lastCheckedDate = lastCheckedInterval > 0.0 ? Date(timeIntervalSinceReferenceDate: lastCheckedInterval) : .distantPast

            pp_log_g(.App.core, .debug, "Version: checking for updates...")
            let fetchedLatestVersion = try await strategy.latestVersion(since: lastCheckedDate)
            kvManager.set(now.timeIntervalSinceReferenceDate, forAppPreference: .lastCheckedVersionDate)
            kvManager.set(fetchedLatestVersion.description, forAppPreference: .lastCheckedVersion)
            pp_log_g(.App.core, .info, "Version: \(fetchedLatestVersion) > \(currentVersion) = \(fetchedLatestVersion > currentVersion)")

#if !PSP_CROSS
            objectWillChange.send()
#endif

            if let latestRelease {
                pp_log_g(.App.core, .info, "Version: new version available at \(latestRelease.url)")
            } else {
                pp_log_g(.App.core, .debug, "Version: current is latest version")
            }
        } catch ABI.AppError.rateLimit {
            pp_log_g(.App.core, .debug, "Version: rate limit")
        } catch ABI.AppError.unexpectedResponse {
            // save the check date regardless because the service call succeeded
            kvManager.set(now.timeIntervalSinceReferenceDate, forAppPreference: .lastCheckedVersionDate)

            pp_log_g(.App.core, .error, "Unable to check version: \(ABI.AppError.unexpectedResponse)")
        } catch {
            pp_log_g(.App.core, .error, "Unable to check version: \(error)")
        }
    }
}

extension VersionChecker {
    private final class DummyStrategy: VersionCheckerStrategy {
        func latestVersion(since: Date) async throws -> ABI.SemanticVersion {
            ABI.SemanticVersion("255.255.255")!
        }
    }

    public convenience init(
        downloadURL: URL = URL(string: "http://")!,
        currentVersion: String = "255.255.255" // An update is never available
    ) {
        self.init(
            kvManager: KeyValueManager(),
            strategy: DummyStrategy(),
            currentVersion: currentVersion,
            downloadURL: downloadURL
        )
    }
}
