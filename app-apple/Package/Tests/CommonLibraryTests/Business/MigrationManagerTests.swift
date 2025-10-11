// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

@testable import CommonLibrary
import CommonUtils
import Foundation
import XCTest

@MainActor
final class MigrationManagerTests: XCTestCase {
}

extension MigrationManagerTests {
    func test_givenStrategy_whenFetchMigratable_thenReturnsMigratable() async throws {
        let strategy = MockProfileMigrationStrategy()
        strategy.migratableProfiles = [
            .init(id: UUID(), name: "one", lastUpdate: nil),
            .init(id: UUID(), name: "two", lastUpdate: nil),
            .init(id: UUID(), name: "three", lastUpdate: nil)
        ]
        let sut = MigrationManager(profileStrategy: strategy)
        let migratable = try await sut.fetchMigratableProfiles()
        XCTAssertEqual(migratable, strategy.migratableProfiles)
    }

    func test_givenStrategy_whenMigrateProfile_thenReturnsMigrated() async throws {
        let uuid = UUID()
        let expProfile = try {
            var builder = Profile.Builder(id: uuid)
            builder.name = "foobar"
            builder.userInfo = ["user": "info"]
            return try builder.tryBuild()
        }()

        let strategy = MockProfileMigrationStrategy()
        strategy.migratableProfiles = [
            .init(id: uuid, name: expProfile.name, lastUpdate: nil)
        ]
        strategy.migratedProfiles = [
            uuid: expProfile
        ]
        let sut = MigrationManager(profileStrategy: strategy)

        let migratable = try await sut.fetchMigratableProfiles()
        XCTAssertEqual(migratable.count, 1)
        let firstMigratable = try XCTUnwrap(migratable.first)

        guard let migrated = try await sut.migratedProfile(withId: firstMigratable.id) else {
            XCTFail("Profile not found")
            return
        }
        XCTAssertEqual(migrated.id, uuid)
        XCTAssertEqual(migrated.name, "foobar")
        XCTAssertEqual(migrated.userInfo?["user"], "info")
    }

    func test_givenStrategy_whenMigrateProfiles_thenReturnsMigratedWithUpdates() async throws {
        let profile1 = try Profile.Builder(name: "one").tryBuild()
        let profile2 = try Profile.Builder(name: "two").tryBuild()
        let strategy = MockProfileMigrationStrategy()
        strategy.migratableProfiles = [
            .init(id: profile1.id, name: profile1.name, lastUpdate: nil),
            .init(id: profile2.id, name: profile2.name, lastUpdate: nil)
        ]
        strategy.migratedProfiles = [
            profile1.id: profile1
        ]
        strategy.failedProfiles = [profile2.id]
        let sut = MigrationManager(profileStrategy: strategy)

        let migratable = try await sut.fetchMigratableProfiles()

        var pending: Set<UUID> = [profile1.id, profile2.id]
        let migrated = try await sut.migratedProfiles(migratable) { uuid, status in
            if pending.contains(uuid) {
                XCTAssertEqual(status, .pending)
                pending.remove(uuid)
                return
            }
            switch uuid {
            case profile1.id:
                XCTAssertEqual(status, .done)
            case profile2.id:
                XCTAssertEqual(status, .failed)
            default:
                XCTFail("Unexpected UUID")
            }
        }

        XCTAssertEqual(migrated, [profile1])
    }

    func test_givenStrategy_whenImportProfiles_thenSavesMigratedWithUpdates() async throws {
        let profile1 = try Profile.Builder(name: "one").tryBuild()
        let profile2 = try Profile.Builder(name: "two").tryBuild()
        let profile3 = try Profile.Builder(name: "three").tryBuild()
        let strategy = MockProfileMigrationStrategy()
        let sut = MigrationManager(profileStrategy: strategy)

        let migrated = [profile1, profile2, profile3]
        let importer = MockMigrationManagerImporter(failing: [profile1.id])
        var pending = Set(migrated.map(\.id))
        await sut.importProfiles(migrated, into: importer) { uuid, status in
            if pending.contains(uuid) {
                XCTAssertEqual(status, .pending)
                pending.remove(uuid)
                return
            }
            switch uuid {
            case profile1.id:
                XCTAssertEqual(status, .failed)
            case profile2.id:
                XCTAssertEqual(status, .done)
            case profile3.id:
                XCTAssertEqual(status, .done)
            default:
                XCTFail("Unexpected UUID")
            }
        }

        let imported = await importer.importedProfiles()
        XCTAssertEqual(imported, [profile2, profile3])
    }

    func test_givenStrategy_whenDeleteMigratable_thenDeletesMigratable() async throws {
        let strategy = MockProfileMigrationStrategy()
        let id1 = UUID()
        let id2 = UUID()
        let id3 = UUID()
        strategy.migratableProfiles = [
            .init(id: id1, name: "one", lastUpdate: nil),
            .init(id: id2, name: "two", lastUpdate: nil),
            .init(id: id3, name: "three", lastUpdate: nil)
        ]
        let sut = MigrationManager(profileStrategy: strategy)
        try await sut.deleteMigratableProfiles(withIds: [id1, id2])
        let migratable = try await sut.fetchMigratableProfiles()
        XCTAssertEqual(migratable.map(\.id), [id3])
    }
}
