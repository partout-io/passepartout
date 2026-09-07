// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

@testable import AppLibrary
import CommonLibrary
import Foundation
import Testing

struct AppImportExportTests {
    let legacyRegistry = CodingRegistry(registry: Registry(withKnown: true))

    @Test
    func givenEffectiveImportFlag_whenDecodeProfile_thenSelectsExpectedDecoder() throws {
        let legacyProfile = try Profile.Builder(name: "legacy").build()
        let encoded = try legacyRegistry.string(fromProfile: legacyProfile)
        let sut = AppImportExport(
            configBlock: { [] },
            importModule: { _, _ in throw ABI.AppError.importError() },
            exportModule: { _ in "" },
            legacyRegistry: legacyRegistry
        )

        let decoded = try sut.profile(fromString: encoded)
        #expect(decoded == legacyProfile)
    }

    @Test(arguments: [true, false])
    func givenEffectiveExportFlag_whenEncodeModule_thenSelectsExpectedEncoder(enabled: Bool) throws {
        let sut = AppImportExport(
            configBlock: { enabled ? [.zigCodingExport] : [] },
            importModule: { _, _ in throw ABI.AppError.importError() },
            exportModule: { _ in "zig" },
            legacyRegistry: legacyRegistry
        )

        let encoded = try sut.exportedModule(from: TestSerializableModule())

        #expect(sut.isEnabled(.zigCodingExport) == enabled)
        #expect(encoded == (enabled ? "zig" : "legacy"))
    }

    @Test
    func givenBinaryFile_whenImportProfile_thenThrowsBinaryFile() throws {
        let sut = AppImportExport(
            configBlock: { [] },
            importModule: { _, _ in throw ABI.AppError.importError() },
            exportModule: { _ in "" },
            legacyRegistry: legacyRegistry
        )
        let url = URL.temporaryDirectory
            .appending(component: UUID().uuidString)
            .appendingPathExtension("bin")
        try Data([0x00, 0x01, 0x02, 0x03]).write(to: url)
        defer {
            try? FileManager.default.removeItem(at: url)
        }

        var didThrowBinaryFile = false
        do {
            _ = try sut.importedProfile(from: .file(url), passphrase: nil)
        } catch ABI.AppError.binaryFile {
            didThrowBinaryFile = true
        } catch {
            throw error
        }
        #expect(didThrowBinaryFile)
    }
}

private struct TestSerializableModule: SerializableModule {
    let preferredExtension = "test"

    func serialized() throws -> String {
        "legacy"
    }
}
