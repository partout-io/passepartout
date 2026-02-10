// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import Partout

@MainActor
public final class ProfileManager {
    private enum Observer: CaseIterable {
        case local
        case remote
    }

    // MARK: Dependencies

    private let repository: ProfileRepository
    private let backupRepository: ProfileRepository?
    private var remoteRepository: ProfileRepository?
    private let mirrorsRemoteRepository: Bool
    private let processor: ProfileProcessor?

    // MARK: State

    private var allProfiles: [Profile.ID: Profile] {
        didSet {
            didChange.send(.localProfiles)
            didChange.send(.refresh(computedProfileHeaders()))
        }
    }

    private var remoteProfilesIds: Set<Profile.ID> {
        didSet {
            didChange.send(.refresh(computedProfileHeaders()))
        }
    }

    public var isRemoteImportingEnabled = false {
        didSet {
            didChange.send(.changeRemoteImporting(isRemoteImportingEnabled))
        }
    }

    private var waitingObservers: Set<Observer> {
        didSet {
            if waitingObservers.isEmpty {
                didChange.send(.ready)
            }
        }
    }

    // MARK: Publishers

    public nonisolated let didChange: PassthroughStream<UniqueID, ABI.ProfileEvent>
    private var localSubscription: Task<Void, Never>?
    private var remoteSubscription: Task<Void, Never>?
    private var remoteImportTask: Task<Void, Never>?

    // For testing/previews
    public convenience init(profiles: [Profile]) {
        self.init(
            repository: InMemoryProfileRepository(profiles: profiles)
        )
    }

    public init(
        processor: ProfileProcessor? = nil,
        repository: ProfileRepository,
        backupRepository: ProfileRepository? = nil,
        mirrorsRemoteRepository: Bool = false,
        readyAfterRemote: Bool = false
    ) {
        self.processor = processor
        self.repository = repository
        self.backupRepository = backupRepository
        self.mirrorsRemoteRepository = mirrorsRemoteRepository

        allProfiles = [:]
        remoteProfilesIds = []
        if readyAfterRemote {
            waitingObservers = [.local, .remote]
        } else {
            waitingObservers = [.local]
        }
        didChange = PassthroughStream()
    }
}

// MARK: - Actions

extension ProfileManager {
    public func save(_ originalProfile: Profile, isLocal: Bool = false, remotelyShared: Bool? = nil) async throws {
        let profile: Profile
        if isLocal {
            var builder = originalProfile.builder()
            if let processor {
                builder = try processor.willRebuild(builder)
            }
            builder.attributes.lastUpdate = Date()
            builder.attributes.fingerprint = UniqueID()
            profile = try builder.build()
        } else {
            profile = originalProfile
        }

        pspLog(.profiles, .notice, "Save profile \(profile.id)...")
        do {
            let existingProfile = allProfiles[profile.id]
            if existingProfile == nil || profile != existingProfile {
                try await repository.saveProfile(profile)
                if let backupRepository {
                    Task.detached {
                        try await backupRepository.saveProfile(profile)
                    }
                }
                didChange.send(.save(profile, previous: existingProfile))
            } else {
                pspLog(.profiles, .notice, "\tProfile \(profile.id) not modified, not saving")
            }
        } catch {
            pspLog(.profiles, .fault, "\tUnable to save profile \(profile.id): \(error)")
            throw error
        }
        if let remoteRepository {
            let enableSharing = remotelyShared == true || (remotelyShared == nil && isLocal && isRemotelyShared(profileWithId: profile.id))
            let disableSharing = remotelyShared == false
            do {
                if enableSharing {
                    pspLog(.profiles, .notice, "\tEnable remote sharing of profile \(profile.id)...")
                    try await remoteRepository.saveProfile(profile)
                } else if disableSharing {
                    pspLog(.profiles, .notice, "\tDisable remote sharing of profile \(profile.id)...")
                    try await remoteRepository.removeProfiles(withIds: [profile.id])
                }
            } catch {
                pspLog(.profiles, .fault, "\tUnable to save/remove remote profile \(profile.id): \(error)")
                throw error
            }
        }
        pspLog(.profiles, .notice, "Finished saving profile \(profile.id)")
    }

    public func duplicate(profileWithId profileId: Profile.ID) async throws {
        guard let profile = allProfiles[profileId] else {
            return
        }

        var builder = profile.builder(withNewId: true)
        builder.name = firstUniqueName(from: profile.name)
        pspLog(.profiles, .notice, "Duplicate profile [\(profileId), \(profile.name)] -> [\(builder.id), \(builder.name)]...")
        let copy = try builder.build()

        try await save(copy)
    }

    public func firstUniqueName(from name: String) -> String {
        let allNames = Set(allProfiles.values.map(\.name))
        var newName = name
        var index = 1
        while true {
            if !allNames.contains(newName) {
                return newName
            }
            newName = [name, index.description].joined(separator: ".")
            index += 1
        }
    }

    public func remove(withId profileId: Profile.ID) async {
        await remove(withIds: [profileId])
    }

    public func remove(withIds profileIds: [Profile.ID]) async {
        pspLog(.profiles, .notice, "Remove profiles \(profileIds)...")
        do {
            try await repository.removeProfiles(withIds: profileIds)
            try? await remoteRepository?.removeProfiles(withIds: profileIds)
        } catch {
            pspLog(.profiles, .fault, "Unable to remove profiles \(profileIds): \(error)")
        }
    }

    public func eraseRemotelySharedProfiles() async throws {
        pspLog(.profiles, .notice, "Erase remotely shared profiles...")
        try await remoteRepository?.removeAllProfiles()
    }

    public func resaveAllProfiles() async {
        for profile in allProfiles.values {
            do {
                try await save(profile, isLocal: true)
            } catch {
                pspLog(.profiles, .error, "Unable to re-save profile \(profile.id): \(error)")
            }
        }
    }
}

// MARK: - State

extension ProfileManager {
    public func profile(withId profileId: Profile.ID) -> Profile? {
        allProfiles[profileId]
    }
}

// MARK: - Observation

extension ProfileManager {
    public func observeLocal() async throws {
        localSubscription = nil
        let initialProfiles = try await repository.fetchProfiles()
        reloadLocalProfiles(initialProfiles)

        let profileEvents = repository.profilesPublisher.dropFirst()
        localSubscription = Task { [weak self] in
            guard let self else { return }
            for await profiles in profileEvents {
                reloadLocalProfiles(profiles)
            }
        }
    }

    public func observeRemote(repository: ProfileRepository) async throws {
        remoteSubscription = nil
        remoteRepository = repository
        let initialProfiles = try await repository.fetchProfiles()
        reloadRemoteProfiles(initialProfiles)

        let profileEvents = repository.profilesPublisher.dropFirst()
        remoteSubscription = Task { [weak self] in
            guard let self else { return }
            for await profiles in profileEvents {
                reloadRemoteProfiles(profiles)
            }
        }
    }
}

private extension ProfileManager {
    func reloadLocalProfiles(_ result: [Profile]) {
        pspLog(.profiles, .info, "Reload local profiles: \(result.map(\.id))")

        let excludedIds = Set(result
            .filter {
                !(processor?.isIncluded($0) ?? true)
            }
            .map(\.id))

        allProfiles = result
            .filter {
                !excludedIds.contains($0.id)
            }
            .reduce(into: [:]) {
                $0[$1.id] = $1
            }

        pspLog(.profiles, .info, "Local profiles after exclusions: \(allProfiles.keys)")

        if waitingObservers.contains(.local) {
            waitingObservers.remove(.local)
        }

        if !excludedIds.isEmpty {
            pspLog(.profiles, .info, "Delete excluded profiles from repository: \(excludedIds)")
            Task {
                // XXX: ignore this published value
                try await repository.removeProfiles(withIds: Array(excludedIds))
            }
        }
    }

    func reloadRemoteProfiles(_ result: [Profile]) {
        pspLog(.profiles, .info, "Reload remote profiles: \(result.map(\.id))")

        remoteProfilesIds = Set(result.map(\.id))
        if waitingObservers.contains(.remote) {
            waitingObservers.remove(.remote)
        }

        Task { [weak self] in
            self?.didChange.send(.startRemoteImport)
            await self?.importRemoteProfiles(result)
            self?.didChange.send(.stopRemoteImport)
        }
    }

    func importRemoteProfiles(_ profiles: [Profile]) async {
        if let previousTask = remoteImportTask {
            pspLog(.profiles, .info, "Cancel ongoing remote import...")
            previousTask.cancel()
            await previousTask.value
            remoteImportTask = nil
        }

        pspLog(.profiles, .info, "Start importing remote profiles: \(profiles.map(\.id))")
        assert(profiles.count == Set(profiles.map(\.id)).count, "Remote repository must not have duplicates")

        pspLog(.profiles, .debug, "Local fingerprints:")
        let localFingerprints: [Profile.ID: UniqueID] = allProfiles.values.reduce(into: [:]) {
            $0[$1.id] = $1.attributes.fingerprint
            pspLog(.profiles, .debug, "\t\($1.id) = \($1.attributes.fingerprint.debugDescription)")
        }
        pspLog(.profiles, .debug, "Remote fingerprints:")
        let remoteFingerprints: [Profile.ID: UniqueID] = profiles.reduce(into: [:]) {
            $0[$1.id] = $1.attributes.fingerprint
            pspLog(.profiles, .debug, "\t\($1.id) = \($1.attributes.fingerprint.debugDescription)")
        }

        let remotelyDeletedIds = Set(allProfiles.keys).subtracting(remoteProfilesIds)
        let mirrorsRemoteRepository = mirrorsRemoteRepository

        remoteImportTask = Task.detached { [weak self] in
            guard let self else {
                return
            }

            var idsToRemove: [Profile.ID] = []
            if !remotelyDeletedIds.isEmpty {
                pspLog(.profiles, .info, "Will \(mirrorsRemoteRepository ? "delete" : "retain") local profiles not present in remote repository: \(remotelyDeletedIds)")
                if mirrorsRemoteRepository {
                    idsToRemove.append(contentsOf: remotelyDeletedIds)
                }
            }
            for remoteProfile in profiles {
                do {
                    guard await processor?.isIncluded(remoteProfile) ?? true else {
                        pspLog(.profiles, .info, "Will delete non-included remote profile \(remoteProfile.id)")
                        idsToRemove.append(remoteProfile.id)
                        continue
                    }
                    if let localFingerprint = localFingerprints[remoteProfile.id] {
                        guard let remoteFingerprint = remoteFingerprints[remoteProfile.id],
                              remoteFingerprint != localFingerprint else {
                            pspLog(.profiles, .info, "Skip re-importing local profile \(remoteProfile.id)")
                            continue
                        }
                    }
                    pspLog(.profiles, .notice, "Import remote profile \(remoteProfile.id)...")
                    try await save(remoteProfile)
                } catch {
                    pspLog(.profiles, .error, "Unable to import remote profile: \(error)")
                }
                guard !Task.isCancelled else {
                    pspLog(.profiles, .info, "Cancelled import of remote profiles: \(profiles.map(\.id))")
                    return
                }
            }

            pspLog(.profiles, .notice, "Finished importing remote profiles, delete stale profiles: \(idsToRemove)")
            if !idsToRemove.isEmpty {
                do {
                    try await repository.removeProfiles(withIds: idsToRemove)
                } catch {
                    pspLog(.profiles, .error, "Unable to delete stale profiles: \(error)")
                }
            }

            // yield a little bit
            try? await Task.sleep(for: .milliseconds(100))
        }
        await remoteImportTask?.value
        remoteImportTask = nil
    }

    func computedProfileHeaders() -> [Profile.ID: ABI.AppProfileHeader] {
        let allHeaders = allProfiles.reduce(into: [:]) {
            $0[$1.key] = $1.value.abiHeader(
                sharingFlags: sharingFlags(for: $1.key),
                requiredFeatures: requiredFeatures(for: $1.value)
            )
        }
        pspLog(.profiles, .info, "Updated headers: \(allHeaders)")
        return allHeaders
    }
}

// MARK: - Helpers

extension ProfileManager {
    func isRemotelyShared(profileWithId profileId: Profile.ID) -> Bool {
        remoteProfilesIds.contains(profileId)
    }

    func isAvailableForTV(profileWithId profileId: Profile.ID) -> Bool {
        allProfiles[profileId]?.attributes.isAvailableForTV == true
    }

    func sharingFlags(for profileId: Profile.ID) -> [ABI.ProfileSharingFlag] {
        if isRemotelyShared(profileWithId: profileId) {
            if isAvailableForTV(profileWithId: profileId) {
                return [.tv]
            } else {
                return [.shared]
            }
        }
        return []
    }

    func requiredFeatures(for profile: Profile) -> Set<ABI.AppFeature> {
        processor?.requiredFeatures(profile) ?? []
    }
}

// MARK: - Testing

extension ProfileManager {
    var isReady: Bool {
        waitingObservers.isEmpty
    }

    var hasProfiles: Bool {
        !allProfiles.isEmpty
    }

    var previews: [ABI.ProfilePreview] {
        allProfiles.map {
            ABI.ProfilePreview($0.value)
        }
    }
}
