// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

@testable import CommonLibraryCore
import Partout
import Testing

@MainActor
struct ProfileManagerTests {
}

// MARK: - View

extension ProfileManagerTests {
    @Test
    func givenStatic_whenNotReady_thenHasProfiles() {
        let profile = newProfile()
        let sut = ProfileManager(profiles: [profile])
        #expect(!sut.isReady)
        #expect(!sut.hasProfiles)
        #expect(sut.profiles.isEmpty)
    }

    @Test
    func givenRepository_whenNotReady_thenHasNoProfiles() {
        let repository = InMemoryProfileRepository(profiles: [])
        let sut = ProfileManager(repository: repository)
        #expect(!sut.isReady)
        #expect(!sut.hasProfiles)
        #expect(sut.profiles.isEmpty)
    }

    @Test
    func givenRepository_whenReady_thenHasProfiles() async throws {
        let profile = newProfile()
        let repository = InMemoryProfileRepository(profiles: [profile])
        let sut = ProfileManager(repository: repository)

        try await waitForReady(sut)
        #expect(sut.isReady)
        #expect(sut.hasProfiles)
        #expect(sut.profiles.count == 1)
        #expect(sut.profile(withId: profile.id) == profile)
    }

    @Test
    func givenRepositoryAndProcessor_whenReady_thenHasInvokedProcessor() async throws {
        let profile = newProfile()
        let repository = InMemoryProfileRepository(profiles: [profile])
        let processor = MockProfileProcessor()
        processor.requiredFeatures = [.appleTV, .onDemand]
        let sut = ProfileManager(processor: processor, repository: repository)

        try await waitForReady(sut)
        #expect(sut.isReady)

        #expect(processor.isIncludedCount == 1)
        #expect(processor.requiredFeaturesCount == 1)
        #expect(processor.willRebuildCount == 0)
        #expect(sut.requiredFeatures(for: profile) == processor.requiredFeatures)
    }

    @Test
    func givenRepositoryAndProcessor_whenIncludedProfiles_thenLoadsIncluded() async throws {
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
        #expect(sut.isReady)

        #expect(sut.profiles.count == 1)
        #expect(sut.profiles.first?.name == "local2")
    }

    @Test
    func givenRepositoryAndProcessor_whenRequiredFeaturesChange_thenMustReload() async throws {
        let profile = newProfile()
        let repository = InMemoryProfileRepository(profiles: [profile])
        let processor = MockProfileProcessor()
        processor.requiredFeatures = [.appleTV, .onDemand]
        let sut = ProfileManager(processor: processor, repository: repository)

        try await waitForReady(sut)
        #expect(sut.isReady)

        #expect(sut.requiredFeatures(for: profile) == processor.requiredFeatures)
        processor.requiredFeatures = [.otp]
        #expect(sut.requiredFeatures(for: profile) == processor.requiredFeatures)

        processor.requiredFeatures = nil
        #expect(sut.requiredFeatures(for: profile).isEmpty)
        processor.requiredFeatures = []
        #expect(sut.requiredFeatures(for: profile).isEmpty)
    }
}

// MARK: - Edit

extension ProfileManagerTests {
    @Test
    func givenRepository_whenSave_thenIsSaved() async throws {
        let repository = InMemoryProfileRepository(profiles: [])
        let sut = ProfileManager(repository: repository)

        try await waitForReady(sut)
        #expect(sut.isReady)
        #expect(!sut.hasProfiles)

        let profile = newProfile()
        try await wait(sut, "Save", until: .localProfiles) {
            try await $0.save(profile)
        }
        #expect(sut.profiles.count == 1)
        #expect(sut.profile(withId: profile.id) == profile)
    }

    @Test
    func givenRepository_whenSaveExisting_thenIsReplaced() async throws {
        let profile = newProfile("oldName")
        let repository = InMemoryProfileRepository(profiles: [profile])
        let sut = ProfileManager(repository: repository)

        try await waitForReady(sut)
        #expect(sut.isReady)
        #expect(sut.profiles.first?.id == profile.id)

        var builder = profile.builder()
        builder.name = "newName"
        let renamedProfile = try builder.build()

        try await wait(sut, "Save", until: .localProfiles) {
            try await $0.save(renamedProfile)
        }
        #expect(sut.profiles.first?.name == renamedProfile.name)
    }

    @Test
    func givenRepositoryAndProcessor_whenSave_thenProcessorIsNotInvoked() async throws {
        let repository = InMemoryProfileRepository(profiles: [])
        let processor = MockProfileProcessor()
        let sut = ProfileManager(processor: processor, repository: repository)

        try await waitForReady(sut)
        #expect(sut.isReady)
        #expect(!sut.hasProfiles)

        let profile = newProfile()
        try await sut.save(profile)
        #expect(processor.willRebuildCount == 0)
        try await sut.save(profile, isLocal: false)
        #expect(processor.willRebuildCount == 0)
    }

    @Test
    func givenRepositoryAndProcessor_whenSaveLocal_thenProcessorIsInvoked() async throws {
        let repository = InMemoryProfileRepository(profiles: [])
        let processor = MockProfileProcessor()
        let sut = ProfileManager(processor: processor, repository: repository)

        try await waitForReady(sut)
        #expect(sut.isReady)
        #expect(!sut.hasProfiles)

        let profile = newProfile()
        try await sut.save(profile, isLocal: true)
        #expect(processor.willRebuildCount == 1)
    }

    @Test
    func givenRepository_whenSave_thenIsStoredToBackUpRepository() async throws {
        let repository = InMemoryProfileRepository(profiles: [])
        let backupRepository = InMemoryProfileRepository(profiles: [])
        let sut = ProfileManager(repository: repository, backupRepository: backupRepository)

        try await waitForReady(sut)
        #expect(sut.isReady)
        #expect(!sut.hasProfiles)

        let profile = newProfile()
        let backupProfiles = backupRepository.profilesPublisher
        let exp = Expectation()
        Task {
            for await profiles in backupProfiles {
                guard !profiles.isEmpty else {
                    continue
                }
                #expect(profiles.first == profile)
                await exp.fulfill()
            }
        }

        try await sut.save(profile)
        try await exp.fulfillment(timeout: CommonLibraryTests.timeout)
    }

    @Test
    func givenRepository_whenRemove_thenIsRemoved() async throws {
        let profile = newProfile()
        let repository = InMemoryProfileRepository(profiles: [profile])
        let sut = ProfileManager(repository: repository)

        try await waitForReady(sut)
        #expect(sut.isReady)
        #expect(sut.hasProfiles)

        try await wait(sut, "Remove", until: .localProfiles) {
            await $0.remove(withId: profile.id)
        }
        #expect(sut.profiles.isEmpty)
    }
}

// MARK: - Remote/Attributes

extension ProfileManagerTests {
    @Test
    func givenRemoteRepository_whenSaveRemotelyShared_thenIsStoredToRemoteRepository() async throws {
        let profile = newProfile()
        let repository = InMemoryProfileRepository()
        let remoteRepository = InMemoryProfileRepository()
        let sut = ProfileManager(repository: repository)

        try await waitForReady(sut, remoteRepository: remoteRepository)

        let remoteProfiles = remoteRepository.profilesPublisher
        let exp = Expectation()
        Task {
            for await profiles in remoteProfiles {
                guard !profiles.isEmpty else {
                    continue
                }
                #expect(profiles.first == profile)
                await exp.fulfill()
            }
        }

        try await sut.save(profile, remotelyShared: true)
        try await exp.fulfillment(timeout: CommonLibraryTests.timeout)

        #expect(sut.isRemotelyShared(profileWithId: profile.id))
    }

    @Test
    func givenRemoteRepository_whenSaveNotRemotelyShared_thenIsRemovedFromRemoteRepository() async throws {
        let profile = newProfile()
        let repository = InMemoryProfileRepository(profiles: [profile])
        let remoteRepository = InMemoryProfileRepository(profiles: [profile])
        let sut = ProfileManager(repository: repository)

        try await waitForReady(sut, remoteRepository: remoteRepository)

        let remoteProfiles = remoteRepository.profilesPublisher
        let exp = Expectation()
        Task {
            for await profiles in remoteProfiles {
                guard profiles.isEmpty else {
                    continue
                }
                await exp.fulfill()
            }
        }

        try await sut.save(profile, remotelyShared: false)
        try await exp.fulfillment(timeout: CommonLibraryTests.timeout)

        #expect(!sut.isRemotelyShared(profileWithId: profile.id))
    }
}

// MARK: - Shortcuts

extension ProfileManagerTests {
    @Test
    func givenRepository_whenNew_thenReturnsProfileWithNewName() async throws {
        let profile = newProfile("example")
        let repository = InMemoryProfileRepository(profiles: [profile])
        let sut = ProfileManager(repository: repository)

        try await waitForReady(sut)
        #expect(sut.profiles.count == 1)

        let newName = sut.firstUniqueName(from: profile.name)
        #expect(newName == "example.1")
    }

    @Test
    func givenRepository_whenDuplicate_thenSavesProfileWithNewName() async throws {
        let profile = newProfile("example")
        let repository = InMemoryProfileRepository(profiles: [profile])
        let sut = ProfileManager(repository: repository)

        try await waitForReady(sut)

        try await wait(sut, "Duplicate 1", until: .localProfiles) {
            try await $0.duplicate(profileWithId: profile.id)
        }
        #expect(sut.profiles.count == 2)

        try await wait(sut, "Duplicate 2", until: .localProfiles) {
            try await $0.duplicate(profileWithId: profile.id)
        }
        #expect(sut.profiles.count == 3)

        try await wait(sut, "Duplicate 3", until: .localProfiles) {
            try await $0.duplicate(profileWithId: profile.id)
        }
        #expect(sut.profiles.count == 4)

        #expect(sut.profiles.map(\.name).sorted() == [
            "example",
            "example.1",
            "example.2",
            "example.3"
        ])
    }
}

// MARK: - Observation

extension ProfileManagerTests {
    @Test
    func givenRemoteRepository_whenUpdatesWithNewProfiles_thenImportsAll() async throws {
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
        #expect(sut.profiles.count == allProfiles.count)

        #expect(Set(sut.profiles) == Set(allProfiles))
        localProfiles.forEach {
            #expect(!sut.isRemotelyShared(profileWithId: $0.id))
        }
        remoteProfiles.forEach {
            #expect(sut.isRemotelyShared(profileWithId: $0.id))
        }
    }

    @Test
    func givenRemoteRepository_whenUpdatesWithExistingProfiles_thenReplacesLocal() async throws {
        let l1 = UniqueID()
        let l2 = UniqueID()
        let l3 = UniqueID()
        let r3 = UniqueID()
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
        #expect(sut.profiles.count == 4) // unique IDs

        sut.profiles.forEach {
            switch $0.id {
            case l1:
                #expect($0.name == "remote1")
                #expect(sut.isRemotelyShared(profileWithId: $0.id))
            case l2:
                #expect($0.name == "remote2")
                #expect(sut.isRemotelyShared(profileWithId: $0.id))
            case l3:
                #expect($0.name == "local3")
                #expect(!sut.isRemotelyShared(profileWithId: $0.id))
            case r3:
                #expect($0.name == "remote3")
                #expect(sut.isRemotelyShared(profileWithId: $0.id))
            default:
                #expect(Bool(false), "Unknown profile: \($0.id)")
            }
        }
    }

    @Test
    func givenRemoteRepository_whenUpdatesWithNotIncludedProfiles_thenImportsNone() async throws {
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

        #expect(processor.isIncludedCount == allProfiles.count)
        #expect(Set(sut.profiles) == Set(localProfiles))
        localProfiles.forEach {
            #expect(!sut.isRemotelyShared(profileWithId: $0.id))
        }
        remoteProfiles.forEach {
            #expect(sut.profile(withId: $0.id) == nil)
            #expect(sut.isRemotelyShared(profileWithId: $0.id))
        }
    }

    @Test
    func givenRemoteRepository_whenUpdatesWithSameFingerprint_thenDoesNotImport() async throws {
        let l1 = UniqueID()
        let l2 = UniqueID()
        let fp1 = UniqueID()
        let localProfiles = [
            newProfile("local1", id: l1, fingerprint: fp1),
            newProfile("local2", id: l2, fingerprint: UniqueID())
        ]
        let remoteProfiles = [
            newProfile("remote1", id: l1, fingerprint: fp1),
            newProfile("remote2", id: l2, fingerprint: UniqueID())
        ]
        let repository = InMemoryProfileRepository(profiles: localProfiles)
        let remoteRepository = InMemoryProfileRepository(profiles: remoteProfiles)
        let processor = MockProfileProcessor()
        let sut = ProfileManager(processor: processor, repository: repository)

        try await wait(sut, "Remote import", until: .stopRemoteImport) {
            try await $0.observeLocal()
            try await $0.observeRemote(repository: remoteRepository)
        }

        try sut.profiles.forEach {
            let profile = try #require(sut.profile(withId: $0.id))
            #expect(sut.isRemotelyShared(profileWithId: $0.id))
            switch $0.id {
            case l1:
                #expect(profile.name == "local1")
                #expect(profile.attributes.fingerprint == localProfiles[0].attributes.fingerprint)
            case l2:
                #expect(profile.name == "remote2")
                #expect(profile.attributes.fingerprint == remoteProfiles[1].attributes.fingerprint)
            default:
                #expect(Bool(false), "Unknown profile: \($0.id)")
            }
        }
    }

    @Test
    func givenRemoteRepository_whenUpdatesMultipleTimes_thenLatestImportWins() async throws {
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
        #expect(sut.profiles.count == localProfiles.count)

        let r1 = UniqueID()
        let r2 = UniqueID()
        let r3 = UniqueID()
        let fp1 = UniqueID()
        let fp2 = UniqueID()
        let fp3 = UniqueID()

        try await wait(sut, "Multiple imports", until: .stopRemoteImport) {
            $0.profiles.count == 5
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
            #expect(!sut.isRemotelyShared(profileWithId: $0.id))
        }
        remoteRepository.profiles.forEach {
            #expect(sut.isRemotelyShared(profileWithId: $0.id))
            switch $0.id {
            case r1:
                #expect($0.attributes.fingerprint == fp1)
            case r2:
                #expect($0.attributes.fingerprint == fp2)
            case r3:
                #expect($0.attributes.fingerprint == fp3)
            default:
                #expect(Bool(false), "Unknown profile: \($0.id)")
            }
        }
    }

    @Test
    func givenRemoteRepository_whenRemoteIsDeleted_thenLocalIsRetained() async throws {
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
        #expect(sut.profiles.count == 1)

        try await wait(sut, "Remote reset", until: .stopRemoteImport) { _ in
            remoteRepository.profiles = []
        }
        #expect(sut.profiles.count == 1)
        #expect(sut.profiles.first == profile)
    }

    @Test
    func givenRemoteRepositoryAndMirroring_whenRemoteIsDeleted_thenLocalIsDeleted() async throws {
        let profile = newProfile()
        let localProfiles = [profile]
        let repository = InMemoryProfileRepository(profiles: localProfiles)
        let remoteRepository = InMemoryProfileRepository(profiles: localProfiles)
        let sut = ProfileManager(repository: repository, mirrorsRemoteRepository: true)

        try await wait(sut, "Remote import", until: .stopRemoteImport) {
            try await $0.observeLocal()
            try await $0.observeRemote(repository: remoteRepository)
        }
        #expect(sut.profiles.count == 1)

        try await wait(sut, "Remote reset", until: .stopRemoteImport) { _ in
            remoteRepository.profiles = []
        }
        #expect(!sut.hasProfiles)
    }
}

// MARK: -

private extension ProfileManagerTests {
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
        until expectedEvent: ABI.ProfileEvent,
        condition: @escaping (ProfileManager) -> Bool = { _ in true },
        after action: (ProfileManager) async throws -> Void
    ) async throws {
        let exp = Expectation()
        var wasMet = false

        let profileEvents = sut.didChange.subscribe()
        Task {
            for await event in profileEvents {
                guard !wasMet else { continue }
                if event == expectedEvent, condition(sut) {
                    wasMet = true
                    await exp.fulfill()
                }
            }
        }

        try await action(sut)
        try await exp.fulfillment(timeout: CommonLibraryTests.timeout)
    }
}
