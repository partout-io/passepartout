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
    func givenLegacyProfile_whenDecodeProfile_thenUsesLegacyRegistry() throws {
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

    @Test
    func givenModule_whenExport_thenUsesABIExporter() throws {
        let sut = AppImportExport(
            configBlock: { [] },
            importModule: { _, _ in throw ABI.AppError.importError() },
            exportModule: { _ in "exported" },
            legacyRegistry: legacyRegistry
        )

        let encoded = try sut.exportedModule(from: OnDemandModule.Builder().build())

        #expect(encoded == "exported")
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
