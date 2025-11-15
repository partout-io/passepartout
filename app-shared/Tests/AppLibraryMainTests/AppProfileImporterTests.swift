// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

@testable import AppLibraryMain
import Combine
import CommonLibrary
import Foundation
import XCTest

final class AppProfileImporterTests: XCTestCase {
    private let importer = SomeModule.Implementation()

    private var subscriptions: Set<AnyCancellable> = []
}

@MainActor
extension AppProfileImporterTests {
    func test_givenNoURLs_whenImport_thenNothingIsImported() async throws {
        let sut = AppProfileImporter()
        let profileManager = ProfileManager(profiles: [])

        try await sut.tryImport(urls: [], profileManager: profileManager, importer: importer)
        XCTAssertEqual(sut.nextURL, nil)
        XCTAssertTrue(profileManager.previews.isEmpty)
    }

    func test_givenURL_whenImport_thenOneProfileIsImported() async throws {
        let sut = AppProfileImporter()
        let profileManager = ProfileManager(profiles: [])
        let url = URL(string: "file:///filename.txt")!

        let exp = expectation(description: "Save")
        profileManager
            .didChange
            .sink {
                switch $0 {
                case .save(let profile, _):
                    XCTAssertEqual(profile.modules.count, 2)
                    XCTAssertTrue(profile.modules.first is SomeModule)
                    XCTAssertTrue(profile.modules.last is OnDemandModule)
                    exp.fulfill()

                default:
                    break
                }
            }
            .store(in: &subscriptions)

        try await sut.tryImport(
            urls: [url],
            profileManager: profileManager,
            importer: importer
        )
        XCTAssertEqual(sut.nextURL, nil)

        await fulfillment(of: [exp])
    }

    func test_givenURLRequiringPassphrase_whenImportWithPassphrase_thenProfileIsImported() async throws {
        let sut = AppProfileImporter()
        let profileManager = ProfileManager(profiles: [])
        let url = URL(string: "file:///filename.encrypted")!

        let exp = expectation(description: "Save")
        profileManager
            .didChange
            .sink {
                switch $0 {
                case .save(let profile, _):
                    XCTAssertEqual(profile.modules.count, 2)
                    XCTAssertTrue(profile.modules.first is SomeModule)
                    XCTAssertTrue(profile.modules.last is OnDemandModule)
                    exp.fulfill()

                default:
                    break
                }
            }
            .store(in: &subscriptions)

        try await sut.tryImport(
            urls: [url],
            profileManager: profileManager,
            importer: importer
        )
        XCTAssertEqual(sut.nextURL, url)

        sut.currentPassphrase = "passphrase"
        try await sut.reImport(url: url, profileManager: profileManager, importer: importer)
        XCTAssertEqual(sut.nextURL, nil)

        await fulfillment(of: [exp])
    }

    func test_givenURLsRequiringPassphrase_whenImport_thenURLsArePending() async throws {
        let sut = AppProfileImporter()
        let profileManager = ProfileManager(profiles: [])
        let url = URL(string: "file:///filename.encrypted")!

        try await sut.tryImport(
            urls: [url, url, url],
            profileManager: profileManager,
            importer: importer
        )
        XCTAssertEqual(sut.nextURL, url)
        XCTAssertEqual(sut.urlsRequiringPassphrase.count, 3)
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
        return try profile(withName: "foobar", singleModule: importedModule)
    }
}
