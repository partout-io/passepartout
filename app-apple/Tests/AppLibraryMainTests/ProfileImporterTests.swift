// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

@testable import AppLibraryMain
@testable import CommonLibraryCore
import Foundation
import Testing

@MainActor
struct ProfileImporterTests {
    @Test
    func givenNoURLs_whenImport_thenNothingIsImported() async throws {
        let sut = ProfileImporter()
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
        let sut = ProfileImporter()
        let profileManager = ProfileManager(profiles: [])
        let url = URL(string: "file:///filename.txt")!

        let exp = Expectation()
        let profileEvents = profileManager.didChange.subscribe()
        Task {
            for await event in profileEvents {
                switch event {
                case .save(let payload):
                    let profile = payload.profile
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
        let sut = ProfileImporter()
        let profileManager = ProfileManager(profiles: [])
        let url = URL(string: "file:///filename.encrypted")!

        let exp = Expectation()
        let profileEvents = profileManager.didChange.subscribe()
        Task {
            for await event in profileEvents {
                switch event {
                case .save(let payload):
                    let profile = payload.profile
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

    @Test(arguments: [OpenVPNErrorCode.passphraseRequired, .unableToDecrypt], [false, true])
    func givenPassphraseError_whenImport_thenQueuesURL(code: OpenVPNErrorCode, wrapped: Bool) async throws {
        let sut = ProfileImporter()
        let url = URL(string: "file:///filename.encrypted")!

        try await sut.tryImport(urls: [url]) { _, _ in
            let error = try openVPNParseError(code)
            if wrapped {
                throw ABI.AppError(error)
            }
            throw error
        }
        #expect(sut.urlsRequiringPassphrase == [url])
    }

    @Test
    func givenUnsupportedCompression_whenImport_thenThrowsWithoutPrompting() async {
        let sut = ProfileImporter()
        let url = URL(string: "file:///filename.ovpn")!

        do {
            try await sut.tryImport(urls: [url]) { _, _ in
                throw try openVPNParseError(.unsupportedCompression)
            }
            Issue.record("Expected unsupported compression error")
        } catch {
            guard case .partout(let wrapped) = error as? ABI.AppError else {
                Issue.record("Expected PartoutError, got \(error)")
                return
            }
            #expect(wrapped.code == .parsing)
            #expect(wrapped.parseErrorInfo?.subCode == OpenVPNErrorCode.unsupportedCompression.rawValue)
        }
        #expect(sut.urlsRequiringPassphrase.isEmpty)
        #expect(!sut.isPresentingPassphrase)
    }

    @Test
    func givenURLsRequiringPassphrase_whenImport_thenURLsArePending() async throws {
        let sut = ProfileImporter()
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
}

private extension ProfileManager {
    func mockImport(url: URL, passphrase: String?) async throws {
        let importedModule = try {
            if url.absoluteString.hasSuffix(".encrypted") {
                guard let passphrase else {
                    throw try openVPNParseError(.passphraseRequired)
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

private func openVPNParseError(_ code: OpenVPNErrorCode) throws -> PartoutError {
    let info = ParseErrorInfo(recognizedType: .OpenVPN, subCode: code.rawValue, arguments: [])
    return PartoutError(.parsing, payload: try JSON(encodable: info))
}
