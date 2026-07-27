// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import Partout
@testable import CommonLibraryCore
import Testing

// Mutable holder for state captured by the applier's @Sendable mock closures.
// @unchecked is safe here because every access happens on @BusinessActor.
private final class Captured<T>: @unchecked Sendable {
    var value: T
    init(_ value: T) { self.value = value }
}

struct ConfigFileApplierTests {
    private struct MockProvider: DeclarativeConfigProvider {
        var configToReturn: DeclarativeConfig?
        var errorToThrow: Error?

        func loadConfig(from data: Data) throws -> DeclarativeConfig {
            if let errorToThrow {
                throw errorToThrow
            }
            return configToReturn ?? DeclarativeConfig()
        }
    }

    @Test
    @BusinessActor
    func givenValidConfig_whenLoadAndApply_thenAppliesAppAndProfiles() async throws {
        // Setup mock file
        let fileURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try "dummy data".write(to: fileURL, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: fileURL) }

        // Setup mock data
        var expectedApp = ABI.AppPreferences.default()
        expectedApp.dnsFallsBack = true
        let expectedProfileName = "TestProfile"
        let mockProvider = MockProvider(configToReturn: DeclarativeConfig(
            app: expectedApp,
            profiles: [TaggedProfile(id: UniqueID(), name: expectedProfileName, modules: [], activeModulesIds: [])]
        ))

        // Tracks calls
        let appliedApp = Captured<ABI.AppPreferences?>(nil)
        let savedProfileNames = Captured<[String]>([])

        let sut = ConfigFileApplier(
            filePath: fileURL.path,
            provider: mockProvider,
            applyPreferences: { prefs in
                appliedApp.value = prefs
            },
            saveProfile: { profile in
                savedProfileNames.value.append(profile.name)
            }
        )

        try await sut.loadAndApply()

        #expect(appliedApp.value?.dnsFallsBack == true)
        #expect(savedProfileNames.value == [expectedProfileName])
    }

    @Test
    @BusinessActor
    func givenMissingFile_whenLoadAndApply_thenDoesNothing() async throws {
        let fileURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let mockProvider = MockProvider(errorToThrow: URLError(.badURL)) // Should not be called

        let applyPreferencesCalled = Captured(false)
        let saveProfileCalled = Captured(false)

        let sut = ConfigFileApplier(
            filePath: fileURL.path,
            provider: mockProvider,
            applyPreferences: { _ in applyPreferencesCalled.value = true },
            saveProfile: { _ in saveProfileCalled.value = true }
        )

        try await sut.loadAndApply()

        #expect(!applyPreferencesCalled.value)
        #expect(!saveProfileCalled.value)
    }

    @Test
    @BusinessActor
    func givenInvalidFile_whenLoadAndApply_thenThrowsError() async throws {
        let fileURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try "dummy data".write(to: fileURL, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: fileURL) }

        struct MockError: Error {}
        let mockProvider = MockProvider(errorToThrow: MockError())

        let applyPreferencesCalled = Captured(false)
        let saveProfileCalled = Captured(false)

        let sut = ConfigFileApplier(
            filePath: fileURL.path,
            provider: mockProvider,
            applyPreferences: { _ in applyPreferencesCalled.value = true },
            saveProfile: { _ in saveProfileCalled.value = true }
        )

        await #expect(throws: Error.self) {
            try await sut.loadAndApply()
        }
        #expect(!applyPreferencesCalled.value)
        #expect(!saveProfileCalled.value)
    }

    @Test
    @BusinessActor
    func givenFailingProfile_whenLoadAndApply_thenAppliesRemainingAndThrows() async throws {
        let fileURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try "dummy data".write(to: fileURL, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: fileURL) }

        struct MockError: Error {}
        let mockProvider = MockProvider(configToReturn: DeclarativeConfig(
            profiles: [
                TaggedProfile(id: UniqueID(), name: "good1", modules: [], activeModulesIds: []),
                TaggedProfile(id: UniqueID(), name: "bad", modules: [], activeModulesIds: []),
                TaggedProfile(id: UniqueID(), name: "good2", modules: [], activeModulesIds: [])
            ]
        ))

        let savedProfileNames = Captured<[String]>([])

        let sut = ConfigFileApplier(
            filePath: fileURL.path,
            provider: mockProvider,
            saveProfile: { profile in
                if profile.name == "bad" {
                    throw MockError()
                }
                savedProfileNames.value.append(profile.name)
            }
        )

        // A single failing profile must not skip the later ones, but the overall
        // apply still surfaces an error.
        await #expect(throws: DeclarativeConfigError.self) {
            try await sut.loadAndApply()
        }
        #expect(savedProfileNames.value == ["good1", "good2"])
    }

    @Test
    @BusinessActor
    func givenCustomModule_whenLoadAndApply_thenUsesCustomHandler() async throws {
        let fileURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try "dummy data".write(to: fileURL, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: fileURL) }

        let custom = CustomModule(innerType: ModuleType("DNS"), json: .object([:]))
        let mockProvider = MockProvider(configToReturn: DeclarativeConfig(
            profiles: [
                TaggedProfile(id: UniqueID(), name: "Custom", modules: [.Custom(custom)], activeModulesIds: [])
            ]
        ))

        let handlerCalled = Captured(false)

        let sut = ConfigFileApplier(
            filePath: fileURL.path,
            provider: mockProvider,
            customHandler: { module in
                handlerCalled.value = true
                return module
            },
            saveProfile: { _ in }
        )

        // Ignore build/save outcome: the point is that the handler is invoked
        // while resolving custom modules.
        try? await sut.loadAndApply()

        #expect(handlerCalled.value)
    }
}

// MARK: - Config path

struct ConfigPathTests {
    @Test
    func givenNilPath_whenResolve_thenUsesDefault() {
        #expect(ConfigFileApplier.resolvedConfigPath(nil) == ConfigFileApplier.defaultConfigPath())
    }

    @Test
    func givenExplicitPath_whenResolve_thenUsesItVerbatim() {
        let explicit = "/etc/passepartout/custom.json"
        #expect(ConfigFileApplier.resolvedConfigPath(explicit) == explicit)
    }

    @Test
    func givenEmptyPath_whenResolve_thenUsesItVerbatim() {
        // An empty string is an explicit (if useless) value, not "absent";
        // only nil means "use the default".
        #expect(ConfigFileApplier.resolvedConfigPath("") == "")
    }

    @Test
    func givenDefaultConfigPath_thenIsHomeConfigJSON() {
        let path = ConfigFileApplier.defaultConfigPath()
        #expect(path.hasPrefix(FileManager.default.homeDirectoryForCurrentUser.path))
        #expect(path.hasSuffix("/.config/passepartout.json"))
    }
}

// MARK: - Providers

struct ConfigProviderTests {
    @Test
    func givenJSONPath_whenMakeProvider_thenReturnsJSONProvider() throws {
        let provider = try ConfigProviderFactory.provider(forFileAtPath: "/tmp/config.json")
        #expect(provider is JSONConfigProvider)
    }

    @Test
    func givenUnsupportedPath_whenMakeProvider_thenThrows() {
        #expect(throws: DeclarativeConfigError.self) {
            _ = try ConfigProviderFactory.provider(forFileAtPath: "/tmp/config.yaml")
        }
    }

    @Test
    func givenValidJSON_whenLoadConfig_thenDecodes() throws {
        var app = ABI.AppPreferences.default()
        app.dnsFallsBack = true
        let data = try ABI.encode(DeclarativeConfig(app: app))

        let config = try JSONConfigProvider().loadConfig(from: data)
        #expect(config.app?.dnsFallsBack == true)
    }

    @Test
    func givenInvalidJSON_whenLoadConfig_thenThrowsParseFailure() {
        let data = Data("{ not json".utf8)
        #expect(throws: DeclarativeConfigError.self) {
            _ = try JSONConfigProvider().loadConfig(from: data)
        }
    }

    @Test
    func givenConfig_whenEncodedAndDecoded_thenRoundTrips() throws {
        var app = ABI.AppPreferences.default()
        app.dnsFallsBack = true
        app.skipsPurchases = true
        let original = DeclarativeConfig(
            app: app,
            profiles: [TaggedProfile(id: UniqueID(), name: "RoundTrip", modules: [], activeModulesIds: [])]
        )

        let data = try ABI.encode(original)
        let decoded = try ABI.decode(DeclarativeConfig.self, from: data)

        #expect(decoded.app?.dnsFallsBack == true)
        #expect(decoded.app?.skipsPurchases == true)
        #expect(decoded.profiles?.map(\.name) == ["RoundTrip"])
    }
}
