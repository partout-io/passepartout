// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import Partout

public typealias ProfileSaveHandler = @Sendable (Profile) async throws -> Void

@BusinessActor
public final class ConfigFileApplier {

    // MARK: - Types

    public enum Event: Sendable {
        case willApply
        case didApply
        case error(Error)
    }

    // MARK: - Public API

    public nonisolated let filePath: String
    public nonisolated let didChange: PassthroughStream<Event>

    /// Default location of the declarative config file, used when the host does
    /// not provide an explicit path. Platform-neutral (all platforms have a home
    /// directory). `nonisolated` as it holds no actor state, so the C ABI entry
    /// point can resolve it before entering the business actor.
    public nonisolated static func defaultConfigPath() -> String {
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".config/passepartout.json")
            .path
    }

    /// Resolves the config path from an optional host-provided value: an explicit
    /// path is used as-is, a nil value falls back to `defaultConfigPath()`. Kept
    /// as a testable seam for the C ABI's NULL-means-default rule.
    public nonisolated static func resolvedConfigPath(_ explicit: String?) -> String {
        explicit ?? defaultConfigPath()
    }

    public var configExists: Bool {
        FileManager.default.fileExists(atPath: filePath)
    }

    public init(
        filePath: String,
        provider: DeclarativeConfigProvider,
        customHandler: TaggedProfile.CustomModuleHandler? = nil,
        applyPreferences: @escaping @Sendable @BusinessActor (ABI.AppPreferences) -> Void = { _ in },
        saveProfile: @escaping ProfileSaveHandler
    ) {
        self.filePath = filePath
        self.provider = provider
        self.customHandler = customHandler
        self.applyPreferences = applyPreferences
        self.saveProfile = saveProfile
        didChange = PassthroughStream()
    }

    public func loadAndApply() async throws {
        guard configExists else { return }

        let data = try readFile()
        let config = try provider.loadConfig(from: data)
        try await apply(config)
    }

    // MARK: - Private

    private let provider: DeclarativeConfigProvider
    private let customHandler: TaggedProfile.CustomModuleHandler?
    private let applyPreferences: @Sendable @BusinessActor (ABI.AppPreferences) -> Void
    private let saveProfile: ProfileSaveHandler

    private func readFile() throws -> Data {
        do {
            return try Data(contentsOf: URL(fileURLWithPath: filePath))
        } catch {
            throw DeclarativeConfigError.unreadableFile(filePath, error)
        }
    }

    private func apply(_ config: DeclarativeConfig) async throws {
        didChange.send(.willApply)
        pspLog(.core, .info, "File config: applying from \(filePath)")

        if let app = config.app {
            applyPreferences(app)
        }
        if let profiles = config.profiles {
            try await applyProfiles(profiles)
        }

        didChange.send(.didApply)
        pspLog(.core, .info, "File config: applied successfully")
    }

    private func applyProfiles(_ profiles: [TaggedProfile]) async throws {
        // Best-effort: a single failing profile must not prevent the remaining
        // ones from being applied. Collect the failures and surface them at the
        // end so the caller can log them, without rolling back what succeeded.
        var failed: [String] = []
        for tagged in profiles {
            do {
                let profile = try tagged.asProfile(customHandler: customHandler)
                try await saveProfile(profile)
                pspLog(.core, .info, "File config: applied profile '\(profile.name)'")
            } catch {
                pspLog(.core, .error, "File config: failed profile '\(tagged.name)': \(error)")
                failed.append(tagged.name)
            }
        }
        if !failed.isEmpty {
            throw DeclarativeConfigError.invalidProfiles(failed)
        }
    }
}


