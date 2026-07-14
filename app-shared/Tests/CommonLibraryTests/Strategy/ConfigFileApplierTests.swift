// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import Partout
@testable import CommonLibraryCore
import Testing

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
        var appliedApp: ABI.AppPreferences?
        var savedProfileNames: [String] = []

        let sut = ConfigFileApplier(
            filePath: fileURL.path,
            provider: mockProvider,
            applyPreferences: { prefs in
                appliedApp = prefs
            },
            saveProfile: { profile in
                savedProfileNames.append(profile.name)
            }
        )

        try await sut.loadAndApply()

        #expect(appliedApp?.dnsFallsBack == true)
        #expect(savedProfileNames == [expectedProfileName])
    }

    @Test
    @BusinessActor
    func givenMissingFile_whenLoadAndApply_thenDoesNothing() async throws {
        let fileURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let mockProvider = MockProvider(errorToThrow: URLError(.badURL)) // Should not be called

        var applyPreferencesCalled = false
        var saveProfileCalled = false

        let sut = ConfigFileApplier(
            filePath: fileURL.path,
            provider: mockProvider,
            applyPreferences: { _ in applyPreferencesCalled = true },
            saveProfile: { _ in saveProfileCalled = true }
        )

        try await sut.loadAndApply()

        #expect(!applyPreferencesCalled)
        #expect(!saveProfileCalled)
    }

    @Test
    @BusinessActor
    func givenInvalidFile_whenLoadAndApply_thenThrowsError() async throws {
        let fileURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try "dummy data".write(to: fileURL, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: fileURL) }

        struct MockError: Error {}
        let mockProvider = MockProvider(errorToThrow: MockError())

        var applyPreferencesCalled = false
        var saveProfileCalled = false

        let sut = ConfigFileApplier(
            filePath: fileURL.path,
            provider: mockProvider,
            applyPreferences: { _ in applyPreferencesCalled = true },
            saveProfile: { _ in saveProfileCalled = true }
        )

        await #expect(throws: Error.self) {
            try await sut.loadAndApply()
        }
        #expect(!applyPreferencesCalled)
        #expect(!saveProfileCalled)
    }
}
