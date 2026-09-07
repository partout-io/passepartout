// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

@testable import AppLibrary
import CommonLibrary
import Foundation
import Testing

struct AppImportExportTests {
    @Test(arguments: [true, false])
    func givenEffectiveImportFlag_whenDecodeProfile_thenSelectsExpectedDecoder(enabled: Bool) throws {
        let registry = CodingRegistry(registry: Registry(withKnown: true))
        let legacyProfile = try Profile.Builder(name: "legacy").build()
        let zigProfile = try Profile.Builder(name: "zig").build()
        let encoded = try registry.string(fromProfile: legacyProfile)
        let sut = AppImportExport(
            configBlock: { enabled ? [.zigCodingImport] : [] },
            importProfile: { _, _ in zigProfile },
            importModule: { _, _ in throw ABI.AppError.importError() },
            exportModule: { _ in "" },
            legacyRegistry: registry
        )

        let decoded = try sut.profile(fromString: encoded)

        #expect(sut.isEnabled(.zigCodingImport) == enabled)
        #expect(decoded == (enabled ? zigProfile : legacyProfile))
    }

    @Test(arguments: [true, false])
    func givenEffectiveExportFlag_whenEncodeModule_thenSelectsExpectedEncoder(enabled: Bool) throws {
        let sut = AppImportExport(
            configBlock: { enabled ? [.zigCodingExport] : [] },
            importProfile: { _, _ in throw ABI.AppError.importError() },
            importModule: { _, _ in throw ABI.AppError.importError() },
            exportModule: { _ in "zig" },
            legacyRegistry: CodingRegistry(registry: Registry(withKnown: true))
        )

        let encoded = try sut.exportedModule(from: TestSerializableModule())

        #expect(sut.isEnabled(.zigCodingExport) == enabled)
        #expect(encoded == (enabled ? "zig" : "legacy"))
    }

    @Test
    func givenBinaryFile_whenImportProfile_thenThrowsBinaryFile() throws {
        let sut = AppImportExport(
            configBlock: { [] },
            importProfile: { _, _ in throw ABI.AppError.importError() },
            importModule: { _, _ in throw ABI.AppError.importError() },
            exportModule: { _ in "" },
            legacyRegistry: CodingRegistry(
                registry: Registry(withKnown: true)
            )
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
