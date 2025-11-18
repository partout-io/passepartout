// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

@testable import CommonLibrary
import Foundation
import XCTest

@MainActor
final class ProfileManagerTests: XCTestCase {
}

// MARK: - View

extension ProfileManagerTests {
    func test_givenStatic_whenNotReady_thenHasProfiles() {
        let profile = newProfile()
        let sut = ProfileManager(profiles: [profile])
        XCTAssertFalse(sut.isReady)
        XCTAssertFalse(sut.hasProfiles)
        XCTAssertTrue(sut.previews.isEmpty)
    }

    func test_givenRepository_whenNotReady_thenHasNoProfiles() {
        let repository = InMemoryProfileRepository(profiles: [])
        let sut = ProfileManager(repository: repository)
        XCTAssertFalse(sut.isReady)
        XCTAssertFalse(sut.hasProfiles)
        XCTAssertTrue(sut.previews.isEmpty)
    }

    func test_givenRepository_whenReady_thenHasProfiles() async throws {
        let profile = newProfile()
        let repository = InMemoryProfileRepository(profiles: [profile])
        let sut = ProfileManager(repository: repository)

        try await waitForReady(sut)
        XCTAssertTrue(sut.isReady)
        XCTAssertTrue(sut.hasProfiles)
        XCTAssertEqual(sut.previews.count, 1)
        XCTAssertEqual(sut.partoutProfile(withId: profile.id), profile)
    }

    func test_givenRepository_whenSearch_thenIsSearching() async throws {
        let profile1 = newProfile("foo")
        let profile2 = newProfile("bar")
        let repository = InMemoryProfileRepository(profiles: [profile1, profile2])
        let sut = ProfileManager(repository: repository)

        try await waitForReady(sut)
        XCTAssertTrue(sut.isReady)
        XCTAssertTrue(sut.hasProfiles)
        XCTAssertEqual(sut.previews.count, 2)

        try await wait(sut, "Search", until: .filteredProfiles) {
            $0.search(byName: "ar")
        }
        XCTAssertTrue(sut.isSearching)
        XCTAssertEqual(sut.previews.count, 1)
        let found = try XCTUnwrap(sut.previews.last)
        XCTAssertEqual(found.id, profile2.id)
    }

    func test_givenRepositoryAndProcessor_whenReady_thenHasInvokedProcessor() async throws {
        let profile = newProfile()
        let repository = InMemoryProfileRepository(profiles: [profile])
        let processor = MockProfileProcessor()
        processor.requiredFeatures = [.appleTV, .onDemand]
        let sut = ProfileManager(processor: processor, repository: repository)

        try await waitForReady(sut)
        XCTAssertTrue(sut.isReady)

        XCTAssertEqual(processor.isIncludedCount, 1)
        // FIXME: #1594, This is called twice while transitioning to observables
//        XCTAssertEqual(processor.requiredFeaturesCount, 1)
        XCTAssertEqual(processor.requiredFeaturesCount, 2)
        XCTAssertEqual(processor.willRebuildCount, 0)
        XCTAssertEqual(sut.requiredFeatures(forProfileWithId: profile.id), processor.requiredFeatures)
    }

    func test_givenRepositoryAndProcessor_whenIncludedProfiles_thenLoadsIncluded() async throws {
        let localProfiles = [
            newProfile("local1"),
            newProfile("local2"),
            newProfile("local3")
        ]
        let repository = InMemoryProfileRepository(profiles: localProfiles)
        let processor = MockProfileProcessor()
        processor.isIncludedBlock = {
            $0.name == "local2"
        }
        let sut = ProfileManager(processor: processor, repository: repository)

        try await waitForReady(sut)
        XCTAssertTrue(sut.isReady)

        XCTAssertEqual(sut.previews.count, 1)
        XCTAssertEqual(sut.previews.first?.name, "local2")
    }

    func test_givenRepositoryAndProcessor_whenRequiredFeaturesChange_thenMustReload() async throws {
        let profile = newProfile()
        let repository = InMemoryProfileRepository(profiles: [profile])
        let processor = MockProfileProcessor()
        processor.requiredFeatures = [.appleTV, .onDemand]
        let sut = ProfileManager(processor: processor, repository: repository)

        try await waitForReady(sut)
        XCTAssertTrue(sut.isReady)

        XCTAssertEqual(sut.requiredFeatures(forProfileWithId: profile.id), processor.requiredFeatures)
        processor.requiredFeatures = [.otp]
        XCTAssertNotEqual(sut.requiredFeatures(forProfileWithId: profile.id), processor.requiredFeatures)
        sut.reloadRequiredFeatures()
        XCTAssertEqual(sut.requiredFeatures(forProfileWithId: profile.id), processor.requiredFeatures)

        processor.requiredFeatures = nil
        XCTAssertNotNil(sut.requiredFeatures(forProfileWithId: profile.id))
        sut.reloadRequiredFeatures()
        XCTAssertNil(sut.requiredFeatures(forProfileWithId: profile.id))
        processor.requiredFeatures = []
        sut.reloadRequiredFeatures()
        XCTAssertNil(sut.requiredFeatures(forProfileWithId: profile.id))
    }
}

// MARK: - Edit

extension ProfileManagerTests {
    func test_givenRepository_whenSave_thenIsSaved() async throws {
        let repository = InMemoryProfileRepository(profiles: [])
        let sut = ProfileManager(repository: repository)

        try await waitForReady(sut)
        XCTAssertTrue(sut.isReady)
        XCTAssertFalse(sut.hasProfiles)

        let profile = newProfile()
        try await wait(sut, "Save", until: .localProfiles) {
            try await $0.save(profile)
        }
        XCTAssertEqual(sut.previews.count, 1)
        XCTAssertEqual(sut.partoutProfile(withId: profile.id), profile)
    }

    func test_givenRepository_whenSaveExisting_thenIsReplaced() async throws {
        let profile = newProfile("oldName")
        let repository = InMemoryProfileRepository(profiles: [profile])
        let sut = ProfileManager(repository: repository)

        try await waitForReady(sut)
        XCTAssertTrue(sut.isReady)
        XCTAssertEqual(sut.previews.first?.id, profile.id)

        var builder = profile.builder()
        builder.name = "newName"
        let renamedProfile = try builder.build()

        try await wait(sut, "Save", until: .localProfiles) {
            try await $0.save(renamedProfile)
        }
        XCTAssertEqual(sut.previews.first?.name, renamedProfile.name)
    }

    func test_givenRepositoryAndProcessor_whenSave_thenProcessorIsNotInvoked() async throws {
        let repository = InMemoryProfileRepository(profiles: [])
        let processor = MockProfileProcessor()
        let sut = ProfileManager(processor: processor, repository: repository)

        try await waitForReady(sut)
        XCTAssertTrue(sut.isReady)
        XCTAssertFalse(sut.hasProfiles)

        let profile = newProfile()
        try await sut.save(profile)
        XCTAssertEqual(processor.willRebuildCount, 0)
        try await sut.save(profile, isLocal: false)
        XCTAssertEqual(processor.willRebuildCount, 0)
    }

    func test_givenRepositoryAndProcessor_whenSaveLocal_thenProcessorIsInvoked() async throws {
        let repository = InMemoryProfileRepository(profiles: [])
        let processor = MockProfileProcessor()
        let sut = ProfileManager(processor: processor, repository: repository)

        try await waitForReady(sut)
        XCTAssertTrue(sut.isReady)
        XCTAssertFalse(sut.hasProfiles)

        let profile = newProfile()
        try await sut.save(profile, isLocal: true)
        XCTAssertEqual(processor.willRebuildCount, 1)
    }

    // FIXME
    func test_givenRepository_whenSave_thenIsStoredToBackUpRepository() async throws {
        let repository = InMemoryProfileRepository(profiles: [])
        let backupRepository = InMemoryProfileRepository(profiles: [])
        let sut = ProfileManager(repository: repository, backupRepository: backupRepository)

        try await waitForReady(sut)
        XCTAssertTrue(sut.isReady)
        XCTAssertFalse(sut.hasProfiles)

        let profile = newProfile()
        let backupProfiles = backupRepository.profilesPublisher
        let exp = expectation(description: "Backup")
        Task {
            for await profiles in backupProfiles {
                guard !profiles.isEmpty else {
                    continue
                }
                XCTAssertEqual(profiles.first, profile)
                exp.fulfill()
            }
        }

        try await sut.save(profile)
        await fulfillment(of: [exp], timeout: CommonLibraryTests.timeout)
    }

    func test_givenRepository_whenRemove_thenIsRemoved() async throws {
        let profile = newProfile()
        let repository = InMemoryProfileRepository(profiles: [profile])
        let sut = ProfileManager(repository: repository)

        try await waitForReady(sut)
        XCTAssertTrue(sut.isReady)
        XCTAssertTrue(sut.hasProfiles)

        try await wait(sut, "Remove", until: .localProfiles) {
            await $0.remove(withId: profile.id)
        }
        XCTAssertTrue(sut.previews.isEmpty)
    }
}

// MARK: - Remote/Attributes

extension ProfileManagerTests {
    func test_givenRemoteRepository_whenSaveRemotelyShared_thenIsStoredToRemoteRepository() async throws {
        let profile = newProfile()
        let repository = InMemoryProfileRepository()
        let remoteRepository = InMemoryProfileRepository()
        let sut = ProfileManager(repository: repository)

        try await waitForReady(sut, remoteRepository: remoteRepository)

        let remoteProfiles = remoteRepository.profilesPublisher
        let exp = expectation(description: "Remote")
        Task {
            for await profiles in remoteProfiles {
                guard !profiles.isEmpty else {
                    continue
                }
                XCTAssertEqual(profiles.first, profile)
                exp.fulfill()
            }
        }

        try await sut.save(profile, remotelyShared: true)
        await fulfillment(of: [exp], timeout: CommonLibraryTests.timeout)

        XCTAssertTrue(sut.isRemotelyShared(profileWithId: profile.id))
    }

    func test_givenRemoteRepository_whenSaveNotRemotelyShared_thenIsRemovedFromRemoteRepository() async throws {
        let profile = newProfile()
        let repository = InMemoryProfileRepository(profiles: [profile])
        let remoteRepository = InMemoryProfileRepository(profiles: [profile])
        let sut = ProfileManager(repository: repository)

        try await waitForReady(sut, remoteRepository: remoteRepository)

        let remoteProfiles = remoteRepository.profilesPublisher
        let exp = expectation(description: "Remote")
        Task {
            for await profiles in remoteProfiles {
                guard profiles.isEmpty else {
                    continue
                }
                exp.fulfill()
            }
        }

        try await sut.save(profile, remotelyShared: false)
        await fulfillment(of: [exp], timeout: CommonLibraryTests.timeout)

        XCTAssertFalse(sut.isRemotelyShared(profileWithId: profile.id))
    }
}

// MARK: - Shortcuts

extension ProfileManagerTests {
    func test_givenRepository_whenNew_thenReturnsProfileWithNewName() async throws {
        let profile = newProfile("example")
        let repository = InMemoryProfileRepository(profiles: [profile])
        let sut = ProfileManager(repository: repository)

        try await waitForReady(sut)
        XCTAssertEqual(sut.previews.count, 1)

        let newName = sut.firstUniqueName(from: profile.name)
        XCTAssertEqual(newName, "example.1")
    }

    func test_givenRepository_whenDuplicate_thenSavesProfileWithNewName() async throws {
        let profile = newProfile("example")
        let repository = InMemoryProfileRepository(profiles: [profile])
        let sut = ProfileManager(repository: repository)

        try await waitForReady(sut)

        try await wait(sut, "Duplicate 1", until: .localProfiles) {
            try await $0.duplicate(profileWithId: profile.id)
        }
        XCTAssertEqual(sut.previews.count, 2)

        try await wait(sut, "Duplicate 2", until: .localProfiles) {
            try await $0.duplicate(profileWithId: profile.id)
        }
        XCTAssertEqual(sut.previews.count, 3)

        try await wait(sut, "Duplicate 3", until: .localProfiles) {
            try await $0.duplicate(profileWithId: profile.id)
        }
        XCTAssertEqual(sut.previews.count, 4)

        XCTAssertEqual(sut.previews.map(\.name), [
            "example",
            "example.1",
            "example.2",
            "example.3"
        ])
    }
}

// MARK: - Observation

extension ProfileManagerTests {
    func test_givenRemoteRepository_whenUpdatesWithNewProfiles_thenImportsAll() async throws {
        let localProfiles = [
            newProfile("local1"),
            newProfile("local2")
        ]
        let remoteProfiles = [
            newProfile("remote1"),
            newProfile("remote2"),
            newProfile("remote3")
        ]
        let allProfiles = localProfiles + remoteProfiles
        let repository = InMemoryProfileRepository(profiles: localProfiles)
        let remoteRepository = InMemoryProfileRepository(profiles: remoteProfiles)
        let sut = ProfileManager(repository: repository)

        try await wait(sut, "Remote import", until: .stopRemoteImport) {
            try await $0.observeLocal()
            try await $0.observeRemote(repository: remoteRepository)
        }
        XCTAssertEqual(sut.previews.count, allProfiles.count)

        XCTAssertEqual(Set(sut.previews), Set(allProfiles.map { ABI.ProfilePreview($0) }))
        localProfiles.forEach {
            XCTAssertFalse(sut.isRemotelyShared(profileWithId: $0.id))
        }
        remoteProfiles.forEach {
            XCTAssertTrue(sut.isRemotelyShared(profileWithId: $0.id))
        }
    }

    func test_givenRemoteRepository_whenUpdatesWithExistingProfiles_thenReplacesLocal() async throws {
        let l1 = UUID()
        let l2 = UUID()
        let l3 = UUID()
        let r3 = UUID()
        let localProfiles = [
            newProfile("local1", id: l1),
            newProfile("local2", id: l2),
            newProfile("local3", id: l3)
        ]
        let remoteProfiles = [
            newProfile("remote1", id: l1),
            newProfile("remote2", id: l2),
            newProfile("remote3", id: r3)
        ]
        let repository = InMemoryProfileRepository(profiles: localProfiles)
        let remoteRepository = InMemoryProfileRepository(profiles: remoteProfiles)
        let sut = ProfileManager(repository: repository)

        try await wait(sut, "Remote import", until: .stopRemoteImport) {
            try await $0.observeLocal()
            try await $0.observeRemote(repository: remoteRepository)
        }
        XCTAssertEqual(sut.previews.count, 4) // unique IDs

        sut.previews.forEach {
            switch $0.id {
            case l1:
                XCTAssertEqual($0.name, "remote1")
                XCTAssertTrue(sut.isRemotelyShared(profileWithId: $0.id))
            case l2:
                XCTAssertEqual($0.name, "remote2")
                XCTAssertTrue(sut.isRemotelyShared(profileWithId: $0.id))
            case l3:
                XCTAssertEqual($0.name, "local3")
                XCTAssertFalse(sut.isRemotelyShared(profileWithId: $0.id))
            case r3:
                XCTAssertEqual($0.name, "remote3")
                XCTAssertTrue(sut.isRemotelyShared(profileWithId: $0.id))
            default:
                XCTFail("Unknown profile: \($0.id)")
            }
        }
    }

    func test_givenRemoteRepository_whenUpdatesWithNotIncludedProfiles_thenImportsNone() async throws {
        let localProfiles = [
            newProfile("local1"),
            newProfile("local2")
        ]
        let remoteProfiles = [
            newProfile("remote1"),
            newProfile("remote2"),
            newProfile("remote3")
        ]
        let allProfiles = localProfiles + remoteProfiles
        let repository = InMemoryProfileRepository(profiles: localProfiles)
        let remoteRepository = InMemoryProfileRepository(profiles: remoteProfiles)
        let processor = MockProfileProcessor()
        processor.isIncludedBlock = {
            !$0.name.hasPrefix("remote")
        }
        let sut = ProfileManager(processor: processor, repository: repository)

        try await wait(sut, "Remote import", until: .stopRemoteImport) {
            try await $0.observeLocal()
            try await $0.observeRemote(repository: remoteRepository)
        }

        XCTAssertEqual(processor.isIncludedCount, allProfiles.count)
        XCTAssertEqual(Set(sut.previews), Set(localProfiles.map { ABI.ProfilePreview($0) }))
        localProfiles.forEach {
            XCTAssertFalse(sut.isRemotelyShared(profileWithId: $0.id))
        }
        remoteProfiles.forEach {
            XCTAssertNil(sut.profile(withId: $0.id))
            XCTAssertTrue(sut.isRemotelyShared(profileWithId: $0.id))
        }
    }

    func test_givenRemoteRepository_whenUpdatesWithSameFingerprint_thenDoesNotImport() async throws {
        let l1 = UUID()
        let l2 = UUID()
        let fp1 = UUID()
        let localProfiles = [
            newProfile("local1", id: l1, fingerprint: fp1),
            newProfile("local2", id: l2, fingerprint: UUID())
        ]
        let remoteProfiles = [
            newProfile("remote1", id: l1, fingerprint: fp1),
            newProfile("remote2", id: l2, fingerprint: UUID())
        ]
        let repository = InMemoryProfileRepository(profiles: localProfiles)
        let remoteRepository = InMemoryProfileRepository(profiles: remoteProfiles)
        let processor = MockProfileProcessor()
        let sut = ProfileManager(processor: processor, repository: repository)

        try await wait(sut, "Remote import", until: .stopRemoteImport) {
            try await $0.observeLocal()
            try await $0.observeRemote(repository: remoteRepository)
        }

        try sut.previews.forEach {
            let profile = try XCTUnwrap(sut.partoutProfile(withId: $0.id))
            XCTAssertTrue(sut.isRemotelyShared(profileWithId: $0.id))
            switch $0.id {
            case l1:
                XCTAssertEqual(profile.name, "local1")
                XCTAssertEqual(profile.attributes.fingerprint, localProfiles[0].attributes.fingerprint)
            case l2:
                XCTAssertEqual(profile.name, "remote2")
                XCTAssertEqual(profile.attributes.fingerprint, remoteProfiles[1].attributes.fingerprint)
            default:
                XCTFail("Unknown profile: \($0.id)")
            }
        }
    }

    func test_givenRemoteRepository_whenUpdatesMultipleTimes_thenLatestImportWins() async throws {
        let localProfiles = [
            newProfile("local1"),
            newProfile("local2")
        ]
        let repository = InMemoryProfileRepository(profiles: localProfiles)
        let remoteRepository = InMemoryProfileRepository()
        let sut = ProfileManager(repository: repository)

        try await wait(sut, "Remote import", until: .stopRemoteImport) {
            try await $0.observeLocal()
            try await $0.observeRemote(repository: remoteRepository)
        }
        XCTAssertEqual(sut.previews.count, localProfiles.count)

        let r1 = UUID()
        let r2 = UUID()
        let r3 = UUID()
        let fp1 = UUID()
        let fp2 = UUID()
        let fp3 = UUID()

        try await wait(sut, "Multiple imports", until: .stopRemoteImport) {
            $0.previews.count == 5
        } after: { _ in
            remoteRepository.profiles = [
                newProfile("remote1", id: r1)
            ]
            remoteRepository.profiles = [
                newProfile("remote1", id: r1),
                newProfile("remote2", id: r2)
            ]
            remoteRepository.profiles = [
                newProfile("remote1", id: r1, fingerprint: fp1),
                newProfile("remote2", id: r2, fingerprint: fp2),
                newProfile("remote3", id: r3, fingerprint: fp3)
            ]
        }

        localProfiles.forEach {
            XCTAssertFalse(sut.isRemotelyShared(profileWithId: $0.id))
        }
        remoteRepository.profiles.forEach {
            XCTAssertTrue(sut.isRemotelyShared(profileWithId: $0.id))
            switch $0.id {
            case r1:
                XCTAssertEqual($0.attributes.fingerprint, fp1)
            case r2:
                XCTAssertEqual($0.attributes.fingerprint, fp2)
            case r3:
                XCTAssertEqual($0.attributes.fingerprint, fp3)
            default:
                XCTFail("Unknown profile: \($0.id)")
            }
        }
    }

    func test_givenRemoteRepository_whenRemoteIsDeleted_thenLocalIsRetained() async throws {
        let profile = newProfile()
        let localProfiles = [profile]
        let remoteProfiles = [profile]
        let repository = InMemoryProfileRepository(profiles: localProfiles)
        let remoteRepository = InMemoryProfileRepository(profiles: remoteProfiles)
        let sut = ProfileManager(repository: repository)

        try await wait(sut, "Remote import", until: .stopRemoteImport) {
            try await $0.observeLocal()
            try await $0.observeRemote(repository: remoteRepository)
        }
        XCTAssertEqual(sut.previews.count, 1)

        try await wait(sut, "Remote reset", until: .stopRemoteImport) { _ in
            remoteRepository.profiles = []
        }
        XCTAssertEqual(sut.previews.count, 1)
        XCTAssertEqual(sut.previews.first, ABI.ProfilePreview(profile))
    }

    func test_givenRemoteRepositoryAndMirroring_whenRemoteIsDeleted_thenLocalIsDeleted() async throws {
        let profile = newProfile()
        let localProfiles = [profile]
        let repository = InMemoryProfileRepository(profiles: localProfiles)
        let remoteRepository = InMemoryProfileRepository(profiles: localProfiles)
        let sut = ProfileManager(repository: repository, mirrorsRemoteRepository: true)

        try await wait(sut, "Remote import", until: .stopRemoteImport) {
            try await $0.observeLocal()
            try await $0.observeRemote(repository: remoteRepository)
        }
        XCTAssertEqual(sut.previews.count, 1)

        try await wait(sut, "Remote reset", until: .stopRemoteImport) { _ in
            remoteRepository.profiles = []
        }
        XCTAssertFalse(sut.hasProfiles)
    }
}

// MARK: -

private extension ProfileManager {
    convenience init(
        processor: ProfileProcessor? = nil,
        repository: ProfileRepository,
        backupRepository: ProfileRepository? = nil,
        mirrorsRemoteRepository: Bool = false,
        readyAfterRemote: Bool = false
    ) {
        self.init(registry: Registry(), processor: processor, repository: repository, backupRepository: backupRepository, mirrorsRemoteRepository: mirrorsRemoteRepository, readyAfterRemote: readyAfterRemote)
    }
}

private extension ProfileManagerTests {
    func newProfile(_ name: String = "", id: UUID? = nil, fingerprint: UUID? = nil) -> Profile {
        do {
            var builder = Profile.Builder(id: id ?? UUID())
            builder.name = name
            if let fingerprint {
                builder.attributes.fingerprint = fingerprint
            }
            return try builder.build()
        } catch {
            fatalError(error.localizedDescription)
        }
    }

    func waitForReady(_ sut: ProfileManager, remoteRepository: ProfileRepository? = nil) async throws {
        try await wait(sut, "Ready", until: .ready) {
            try await $0.observeLocal()
            if let remoteRepository {
                try await $0.observeRemote(repository: remoteRepository)
            }
        }
    }

    func wait(
        _ sut: ProfileManager,
        _ description: String,
        until expectedEvent: ProfileManager.Event,
        condition: @escaping (ProfileManager) -> Bool = { _ in true },
        after action: (ProfileManager) async throws -> Void
    ) async throws {
        let exp = expectation(description: description)
        var wasMet = false

        let profileEvents = sut.didChange.subscribe()
        Task {
            for await event in profileEvents {
                guard !wasMet else { continue }
                if event == expectedEvent, condition(sut) {
                    wasMet = true
                    exp.fulfill()
                }
            }
        }

        try await action(sut)
        await fulfillment(of: [exp], timeout: CommonLibraryTests.timeout)
    }
}
