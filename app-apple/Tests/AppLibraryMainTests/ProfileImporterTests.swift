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
            inputs: [],
            block: profileManager.mockImport
        )
        #expect(sut.nextInput == nil)
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
            inputs: [.file(url)],
            block: profileManager.mockImport
        )
        #expect(sut.nextInput == nil)

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
            inputs: [.file(url)],
            block: profileManager.mockImport
        )
        #expect(sut.nextInput?.displayName == url.lastPathComponent)

        sut.currentPassphrase = "passphrase"
        try await sut.reImport(
            input: .file(url),
            block: profileManager.mockImport
        )
        #expect(sut.nextInput == nil)

        try await exp.fulfillment(timeout: 500)
    }

    @Test(arguments: [OpenVPNErrorCode.passphraseRequired, .unableToDecrypt], [false, true])
    func givenPassphraseError_whenImport_thenQueuesURL(code: OpenVPNErrorCode, wrapped: Bool) async throws {
        let sut = ProfileImporter()
        let url = URL(string: "file:///filename.encrypted")!

        try await sut.tryImport(inputs: [.file(url)]) { _, _ in
            let error = try openVPNParseError(code)
            if wrapped {
                throw ABI.AppError(error)
            }
            throw error
        }
        #expect(sut.inputsRequiringPassphrase.map(\.displayName) == [url.lastPathComponent])
    }

    @Test
    func givenUnsupportedCompression_whenImport_thenThrowsWithoutPrompting() async {
        let sut = ProfileImporter()
        let url = URL(string: "file:///filename.ovpn")!

        do {
            try await sut.tryImport(inputs: [.file(url)]) { _, _ in
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
        #expect(sut.inputsRequiringPassphrase.isEmpty)
        #expect(!sut.isPresentingPassphrase)
    }

    @Test
    func givenURLsRequiringPassphrase_whenImport_thenURLsArePending() async throws {
        let sut = ProfileImporter()
        let profileManager = ProfileManager(profiles: [])
        let url = URL(string: "file:///filename.encrypted")!

        try await sut.tryImport(
            inputs: [.file(url), .file(url), .file(url)],
            block: profileManager.mockImport
        )
        #expect(sut.nextInput?.displayName == url.lastPathComponent)
        #expect(sut.inputsRequiringPassphrase.count == 3)
    }

    @Test
    func givenArchiveEntry_whenImportFails_thenOthersAreImported() async throws {
        let sut = ProfileImporter()
        let inputs: [ABI.ProfileImporterInput] = [
            .contents(filename: "one.ovpn", data: ""),
            .contents(filename: "bad.ovpn", data: ""),
            .contents(filename: "two.ovpn", data: "")
        ]

        let summary = try await sut.tryImport(inputs: inputs) { input, _ in
            if input.displayName == "bad.ovpn" {
                throw ABI.AppError.importError()
            }
        }
        #expect(summary.imported == 2)
        #expect(summary.failed == 1)
    }

    @Test
    func givenFile_whenImportFails_thenThrows() async {
        let sut = ProfileImporter()
        let url = URL(string: "file:///filename.ovpn")!

        await #expect(throws: ABI.AppError.self) {
            try await sut.tryImport(inputs: [.file(url)]) { _, _ in
                throw ABI.AppError.importError()
            }
        }
    }

    @Test
    func givenArchiveEntryRequiringPassphrase_whenImport_thenQueuesWithoutCounting() async throws {
        let sut = ProfileImporter()

        let summary = try await sut.tryImport(inputs: [
            .contents(filename: "encrypted.ovpn", data: "")
        ]) { _, _ in
            throw try openVPNParseError(.passphraseRequired)
        }
        #expect(summary.imported == 0)
        #expect(summary.failed == 0)
        #expect(sut.nextInput?.displayName == "encrypted.ovpn")
    }
}

// MARK: -

private struct SomeModule: Module {
}

private extension ProfileManager {
    func mockImport(input: ABI.ProfileImporterInput, passphrase: String?) async throws {
        let importedModule = try {
            if input.displayName.hasSuffix(".encrypted") {
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
