// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

@testable import CommonLibraryCore
import Foundation
import Partout
import Testing

struct CodingRegistryTests {
    @Test
    func givenBinaryFile_whenImportProfile_thenThrowsBinaryFile() throws {
        let sut = CodingRegistry(
            registry: Registry(withKnown: true),
            withLegacyEncoding: { false }
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
