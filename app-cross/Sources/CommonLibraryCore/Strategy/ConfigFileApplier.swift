// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import Partout

public typealias ProfileSaveHandler = @Sendable (Profile) async throws -> Void

@BusinessActor
public final class ConfigFileApplier {
    public enum Event: Sendable {
        case willApply
        case didApply
        case error(Error)
    }

    public nonisolated let filePath: String
    private let provider: DeclarativeConfigProvider
    private let applyPreferences: @Sendable @BusinessActor (ABI.AppPreferences) -> Void
    private let saveProfile: ProfileSaveHandler

    public nonisolated let didChange: PassthroughStream<Event>

    // Storage for platform-specific file watcher (set by CommonLibraryApple extension)
    nonisolated(unsafe) var fileWatcherStorage: AnyObject?

    public nonisolated init(
        filePath: String,
        provider: DeclarativeConfigProvider,
        applyPreferences: @escaping @Sendable @BusinessActor (ABI.AppPreferences) -> Void,
        saveProfile: @escaping ProfileSaveHandler
    ) {
        self.filePath = filePath
        self.provider = provider
        self.applyPreferences = applyPreferences
        self.saveProfile = saveProfile
        didChange = PassthroughStream()
    }

    public var configExists: Bool {
        FileManager.default.fileExists(atPath: filePath)
    }

    public func loadAndApply() async throws {
        guard configExists else { return }
        let data = try readFile()
        let config = try provider.loadConfig(from: data)
        try await apply(config)
    }

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
        for tagged in profiles {
            do {
                let profile = try tagged.asProfile()
                try await saveProfile(profile)
                pspLog(.core, .info, "File config: applied profile '\(profile.name)'")
            } catch {
                throw DeclarativeConfigError.invalidProfile(tagged.name, error)
            }
        }
    }
}
