// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

@testable import CommonLibraryCore
import Foundation
import Partout
import Testing

struct FileProfileRepositoryTests {
    @Test
    func givenRepository_whenSaveAndReload_thenPersistsProfiles() async throws {
        let directoryURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        defer {
            try? FileManager.default.removeItem(at: directoryURL)
        }

        let firstProfile = newProfile("alpha")
        let secondProfile = newProfile("beta")
        let repository = try FileProfileRepository(directoryURL: directoryURL)

        let publishedProfiles = repository.profilesPublisher
        let exp = Expectation()
        Task {
            var isFirstEvent = true
            for await profiles in publishedProfiles {
                if isFirstEvent {
                    isFirstEvent = false
                    continue
                }
                if profiles.map(\.id) == [firstProfile.id, secondProfile.id] {
                    await exp.fulfill()
                    return
                }
            }
        }

        try await repository.saveProfile(secondProfile)
        try await repository.saveProfile(firstProfile)
        try await exp.fulfillment(timeout: CommonLibraryTests.timeout)

        let reloadedRepository = try FileProfileRepository(directoryURL: directoryURL)
        let profiles = try await reloadedRepository.fetchProfiles()

        #expect(profiles.count == 2)
        #expect(profiles.map(\.id) == [firstProfile.id, secondProfile.id])
        #expect(
            FileManager.default.fileExists(
                atPath: directoryURL.appendingPathComponent("index.json").path
            )
        )
        #expect(
            FileManager.default.fileExists(
                atPath: directoryURL
                    .appendingPathComponent("objects", isDirectory: true)
                    .appendingPathComponent("\(firstProfile.id.uuidString).json")
                    .path
            )
        )
    }
}

private extension FileProfileRepositoryTests {
    func newProfile(_ name: String = "", id: UniqueID? = nil, fingerprint: UniqueID? = nil) -> Profile {
        do {
            var builder = Profile.Builder(id: id ?? UniqueID())
            builder.name = name
            if let fingerprint {
                builder.attributes.fingerprint = fingerprint
            }
            return try builder.build()
        } catch {
            fatalError(error.localizedDescription)
        }
    }
}
