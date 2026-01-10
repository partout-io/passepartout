// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

@testable import AppLibraryMain
import CommonLibrary
import Foundation
import Testing

@MainActor
struct AppProfileImporterTests {
    @Test
    func givenNoURLs_whenImport_thenNothingIsImported() async throws {
        let sut = AppProfileImporter()
        let profileManager = ProfileManager(profiles: [])

        try await sut.tryImport(
            urls: [],
            block: profileManager.mockImport
        )
        #expect(sut.nextURL == nil)
        #expect(!profileManager.hasProfiles)
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
            block: profileManager.mockImport
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
            block: profileManager.mockImport
        )
        #expect(sut.nextURL == url)

        sut.currentPassphrase = "passphrase"
        try await sut.reImport(
            url: url,
            block: profileManager.mockImport
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
            block: profileManager.mockImport
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

private extension ProfileManager {
    func mockImport(url: URL, passphrase: String?) async throws {
        let importedModule = try {
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
        let profile = try Profile(withName: "foobar", singleModule: importedModule)
        try await save(profile, isLocal: true)
    }
}
