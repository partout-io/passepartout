// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

@testable import AppLibraryMainLegacy
import CommonLibrary
import Foundation
import Testing

struct AppProfileImporterTests {
    private let importer = SomeModule.Implementation()
}

@MainActor
extension AppProfileImporterTests {
    @Test
    func givenNoURLs_whenImport_thenNothingIsImported() async throws {
        let sut = AppProfileImporter()
        let profileManager = ProfileManager(profiles: [])

        try await sut.tryImport(
            urls: [],
            profileManager: profileManager,
            registry: Registry(),
            importer: importer
        )
        #expect(sut.nextURL == nil)
        #expect(profileManager.previews.isEmpty)
    }

    @Test
    func givenURL_whenImport_thenOneProfileIsImported() async throws {
        let sut = AppProfileImporter()
        let profileManager = ProfileManager(profiles: [])
        let url = URL(string: "file:///filename.txt")!

        let exp = Expectation()
        let profileEvents = profileManager.didChange.subscribe()
        Task {
            for await event in profileEvents {
                switch event {
                case .save(let profile, _):
                    #expect(profile.modules.count == 2)
                    #expect(profile.modules.first is SomeModule)
                    #expect(profile.modules.last is OnDemandModule)
                    await exp.fulfill()
                default:
                    break
                }
            }
        }

        try await sut.tryImport(
            urls: [url],
            profileManager: profileManager,
            registry: Registry(),
            importer: importer
        )
        #expect(sut.nextURL == nil)

        try await exp.fulfillment(timeout: 500)
    }

    @Test
    func givenURLRequiringPassphrase_whenImportWithPassphrase_thenProfileIsImported() async throws {
        let sut = AppProfileImporter()
        let profileManager = ProfileManager(profiles: [])
        let url = URL(string: "file:///filename.encrypted")!

        let exp = Expectation()
        let profileEvents = profileManager.didChange.subscribe()
        Task {
            for await event in profileEvents {
                switch event {
                case .save(let profile, _):
                    #expect(profile.modules.count == 2)
                    #expect(profile.modules.first is SomeModule)
                    #expect(profile.modules.last is OnDemandModule)
                    await exp.fulfill()
                default:
                    break
                }
            }
        }

        try await sut.tryImport(
            urls: [url],
            profileManager: profileManager,
            registry: Registry(),
            importer: importer
        )
        #expect(sut.nextURL == url)

        sut.currentPassphrase = "passphrase"
        try await sut.reImport(
            url: url,
            profileManager: profileManager,
            registry: Registry(),
            importer: importer
        )
        #expect(sut.nextURL == nil)

        try await exp.fulfillment(timeout: 500)
    }

    @Test
    func givenURLsRequiringPassphrase_whenImport_thenURLsArePending() async throws {
        let sut = AppProfileImporter()
        let profileManager = ProfileManager(profiles: [])
        let url = URL(string: "file:///filename.encrypted")!

        try await sut.tryImport(
            urls: [url, url, url],
            profileManager: profileManager,
            registry: Registry(),
            importer: importer
        )
        #expect(sut.nextURL == url)
        #expect(sut.urlsRequiringPassphrase.count == 3)
    }
}

// MARK: -

private struct SomeModule: Module {
    final class Implementation: ModuleImplementation {
        var moduleHandlerId: ModuleType {
            moduleHandler.id
        }
    }
}

extension SomeModule.Implementation: ProfileImporter {
    func importedProfile(from input: ABI.ProfileImporterInput, passphrase: String?) throws -> Profile {
        let importedModule: Module
        switch input {
        case .contents:
            fatalError()
        case .file(let url):
            importedModule = try {
                if url.absoluteString.hasSuffix(".encrypted") {
                    guard let passphrase else {
                        throw PartoutError(.OpenVPN.passphraseRequired)
                    }
                    guard passphrase == "passphrase" else {
                        throw PartoutError(.crypto)
                    }
                }
                return SomeModule()
            }()
        }
        return try Profile(withName: "foobar", singleModule: importedModule)
    }
}
