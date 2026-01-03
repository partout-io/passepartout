// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#if !PSP_CROSS
extension VersionChecker: ObservableObject {}
#endif

@MainActor
public final class VersionChecker {
    private let kvStore: KeyValueStore

    private let strategy: VersionCheckerStrategy

    private let currentVersion: ABI.SemanticVersion

    private let downloadURL: URL

    private var isPending = false

    public nonisolated let didChange: PassthroughStream<UniqueID, ABI.VersionEvent>

    public init(
        kvStore: KeyValueStore,
        strategy: VersionCheckerStrategy,
        currentVersion: String,
        downloadURL: URL
    ) {
        guard let semCurrent = ABI.SemanticVersion(currentVersion) else {
            preconditionFailure("Unparsable current version: \(currentVersion)")
        }
        self.kvStore = kvStore
        self.strategy = strategy
        self.currentVersion = semCurrent
        self.downloadURL = downloadURL
        didChange = PassthroughStream()
    }

    public var latestRelease: ABI.VersionRelease? {
        guard let latestVersionDescription = kvStore.string(forAppPreference: .lastCheckedVersion),
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
            let lastCheckedInterval = kvStore.double(forAppPreference: .lastCheckedVersionDate)
            let lastCheckedDate = lastCheckedInterval > 0.0 ? Date(timeIntervalSinceReferenceDate: lastCheckedInterval) : .distantPast

            pp_log_g(.App.core, .debug, "Version: checking for updates...")
            let fetchedLatestVersion = try await strategy.latestVersion(since: lastCheckedDate)
            kvStore.set(now.timeIntervalSinceReferenceDate, forAppPreference: .lastCheckedVersionDate)
            kvStore.set(fetchedLatestVersion.description, forAppPreference: .lastCheckedVersion)
            pp_log_g(.App.core, .info, "Version: \(fetchedLatestVersion) > \(currentVersion) = \(fetchedLatestVersion > currentVersion)")

#if !PSP_CROSS
            objectWillChange.send()
#endif
            didChange.send(.new)

            if let latestRelease {
                pp_log_g(.App.core, .info, "Version: new version available at \(latestRelease.url)")
            } else {
                pp_log_g(.App.core, .debug, "Version: current is latest version")
            }
        } catch ABI.AppError.rateLimit {
            pp_log_g(.App.core, .debug, "Version: rate limit")
        } catch ABI.AppError.unexpectedResponse {
            // save the check date regardless because the service call succeeded
            kvStore.set(now.timeIntervalSinceReferenceDate, forAppPreference: .lastCheckedVersionDate)

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
            kvStore: InMemoryStore(),
            strategy: DummyStrategy(),
            currentVersion: currentVersion,
            downloadURL: downloadURL
        )
    }
}
