//
//  AppProfileImporterTests.swift
//  Passepartout
//
//  Created by Davide De Rosa on 9/12/24.
//  Copyright (c) 2025 Davide De Rosa. All rights reserved.
//
//  https://github.com/passepartoutvpn
//
//  This file is part of Passepartout.
//
//  Passepartout is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  Passepartout is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with Passepartout.  If not, see <http://www.gnu.org/licenses/>.
//

@testable import AppUIMain
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
                case .save(let profile):
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
                case .save(let profile):
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
    struct Implementation: ModuleImplementation {
        var moduleHandlerId: ModuleType {
            moduleHandler.id
        }
    }
}

extension SomeModule.Implementation: ProfileImporter {
    func profile(from input: ProfileImporterInput, passphrase: String?) throws -> Profile {
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
