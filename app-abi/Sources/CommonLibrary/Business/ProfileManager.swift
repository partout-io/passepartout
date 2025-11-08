// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import Combine
import Foundation

@MainActor
public final class ProfileManager: ObservableObject {
    private enum Observer: CaseIterable {
        case local

        case remote
    }

    public enum Event: Equatable {
        case ready

        case save(Profile, previous: Profile?)

        case remove([Profile.ID])

        case localProfiles

        case filteredProfiles

        case remoteProfiles

        case startRemoteImport

        case stopRemoteImport
    }

    // MARK: Dependencies

    private let repository: ProfileRepository

    private let backupRepository: ProfileRepository?

    private var remoteRepository: ProfileRepository?

    private let mirrorsRemoteRepository: Bool

    private let processor: ProfileProcessor?

    // MARK: State

//    private var allProfiles: [Profile.ID: Profile] {
//        didSet {
//            didChange.send(.localProfiles)
//
//            reloadFilteredProfiles(with: searchSubject.value)
//            reloadRequiredFeatures()
//        }
//    }
//
//    private var allRemoteProfiles: [Profile.ID: Profile] {
//        didSet {
//            didChange.send(.remoteProfiles)
//        }
//    }
//
//    private var filteredProfiles: [Profile] {
//        didSet {
//            didChange.send(.filteredProfiles)
//        }
//    }
//
//    @Published
//    private var requiredFeatures: [Profile.ID: Set<AppFeature>]
//
//    @Published
//    public var isRemoteImportingEnabled = false
//
//    private var waitingObservers: Set<Observer> {
//        didSet {
//            if isReady {
//                didChange.send(.ready)
//            }
//        }
//    }

    // MARK: Publishers

    public let didChange: PassthroughSubject<Event, Never>

    private let searchSubject: CurrentValueSubject<String, Never>

    private var localSubscription: AnyCancellable?

    private var remoteSubscription: AnyCancellable?

    private var searchSubscription: AnyCancellable?

    private var remoteImportTask: Task<Void, Never>?

    // for testing/previews
    public convenience init(profiles: [Profile]) {
        self.init(repository: InMemoryProfileRepository(profiles: profiles))
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
        allRemoteProfiles = [:]
        filteredProfiles = []
        requiredFeatures = [:]
        if readyAfterRemote {
            waitingObservers = [.local, .remote]
        } else {
            waitingObservers = [.local]
        }

        didChange = PassthroughSubject()
        searchSubject = CurrentValueSubject("")

        observeSearch()
    }
}

// MARK: - View

extension ProfileManager {
    public var isReady: Bool {
        waitingObservers.isEmpty
    }

    public var hasProfiles: Bool {
        !filteredProfiles.isEmpty
    }

    public var previews: [ProfilePreview] {
        filteredProfiles.map {
            processor?.preview(from: $0) ?? ProfilePreview($0)
        }
    }

    public func profile(withId profileId: Profile.ID) -> Profile? {
        allProfiles[profileId]
    }

    public var isSearching: Bool {
        !searchSubject.value.isEmpty
    }

    public func search(byName name: String) {
        searchSubject.send(name)
    }

    public func requiredFeatures(forProfileWithId profileId: Profile.ID) -> Set<AppFeature>? {
        requiredFeatures[profileId]
    }

    public func reloadRequiredFeatures() {
        guard let processor else {
            return
        }
        requiredFeatures = allProfiles.reduce(into: [:]) {
            guard let ineligible = processor.requiredFeatures($1.value), !ineligible.isEmpty else {
                return
            }
            $0[$1.key] = ineligible
        }
        pp_log_g(.App.profiles, .info, "Required features: \(requiredFeatures)")
    }
}

// MARK: - Edit

extension ProfileManager {
    public func save(_ originalProfile: Profile, isLocal: Bool = false, remotelyShared: Bool? = nil) async throws {
        let profile: Profile
        if isLocal {
            var builder = originalProfile.builder()
            if let processor {
                builder = try processor.willRebuild(builder)
            }
            builder.attributes.lastUpdate = Date()
            builder.attributes.fingerprint = UUID()
            profile = try builder.build()
        } else {
            profile = originalProfile
        }

        pp_log_g(.App.profiles, .notice, "Save profile \(profile.id)...")
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
                pp_log_g(.App.profiles, .notice, "\tProfile \(profile.id) not modified, not saving")
            }
        } catch {
            pp_log_g(.App.profiles, .fault, "\tUnable to save profile \(profile.id): \(error)")
            throw error
        }
        if let remoteRepository {
            let enableSharing = remotelyShared == true || (remotelyShared == nil && isLocal && isRemotelyShared(profileWithId: profile.id))
            let disableSharing = remotelyShared == false
            do {
                if enableSharing {
                    pp_log_g(.App.profiles, .notice, "\tEnable remote sharing of profile \(profile.id)...")
                    try await remoteRepository.saveProfile(profile)
                } else if disableSharing {
                    pp_log_g(.App.profiles, .notice, "\tDisable remote sharing of profile \(profile.id)...")
                    try await remoteRepository.removeProfiles(withIds: [profile.id])
                }
            } catch {
                pp_log_g(.App.profiles, .fault, "\tUnable to save/remove remote profile \(profile.id): \(error)")
                throw error
            }
        }
        pp_log_g(.App.profiles, .notice, "Finished saving profile \(profile.id)")
    }

    public func remove(withId profileId: Profile.ID) async {
        await remove(withIds: [profileId])
    }

    public func remove(withIds profileIds: [Profile.ID]) async {
        pp_log_g(.App.profiles, .notice, "Remove profiles \(profileIds)...")
        do {
            try await repository.removeProfiles(withIds: profileIds)
            try? await remoteRepository?.removeProfiles(withIds: profileIds)
            didChange.send(.remove(profileIds))
        } catch {
            pp_log_g(.App.profiles, .fault, "Unable to remove profiles \(profileIds): \(error)")
        }
    }
}

// MARK: - Remote/Attributes

extension ProfileManager {
    public func isRemotelyShared(profileWithId profileId: Profile.ID) -> Bool {
        allRemoteProfiles.keys.contains(profileId)
    }

    public func isAvailableForTV(profileWithId profileId: Profile.ID) -> Bool {
        profile(withId: profileId)?.attributes.isAvailableForTV == true
    }

    public func eraseRemotelySharedProfiles() async throws {
        pp_log_g(.App.profiles, .notice, "Erase remotely shared profiles...")
        try await remoteRepository?.removeAllProfiles()
    }
}

// MARK: - Shortcuts

extension ProfileManager {
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

    public func duplicate(profileWithId profileId: Profile.ID) async throws {
        guard let profile = profile(withId: profileId) else {
            return
        }

        var builder = profile.builder(withNewId: true)
        builder.name = firstUniqueName(from: profile.name)
        pp_log_g(.App.profiles, .notice, "Duplicate profile [\(profileId), \(profile.name)] -> [\(builder.id), \(builder.name)]...")
        let copy = try builder.build()

        try await save(copy)
    }

    public func resaveAllProfiles() async {
        for preview in previews {
            guard let profile = profile(withId: preview.id) else {
                continue
            }
            do {
                try await save(profile, isLocal: true)
            } catch {
                pp_log_g(.App.profiles, .error, "Unable to re-save profile \(preview.id): \(error)")
            }
        }
    }
}

// MARK: - Observation

extension ProfileManager {
    public func observeLocal() async throws {
        localSubscription = nil
        let initialProfiles = try await repository.fetchProfiles()
        reloadLocalProfiles(initialProfiles)

        localSubscription = repository
            .profilesPublisher
            .dropFirst()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in
                self?.reloadLocalProfiles($0)
            }
    }

    public func observeRemote(repository: ProfileRepository) async throws {
        remoteSubscription = nil
        remoteRepository = repository
        let initialProfiles = try await repository.fetchProfiles()
        reloadRemoteProfiles(initialProfiles)

        remoteSubscription = repository
            .profilesPublisher
            .dropFirst()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in
                self?.reloadRemoteProfiles($0)
            }
    }
}

private extension ProfileManager {
    func observeSearch(debounce: Int = 200) {
        searchSubscription = searchSubject
            .debounce(for: .milliseconds(debounce), scheduler: DispatchQueue.main)
            .sink { [weak self] in
                self?.reloadFilteredProfiles(with: $0)
            }
    }
}

private extension ProfileManager {
    func reloadLocalProfiles(_ result: [Profile]) {
        objectWillChange.send()
        pp_log_g(.App.profiles, .info, "Reload local profiles: \(result.map(\.id))")

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

        pp_log_g(.App.profiles, .info, "Local profiles after exclusions: \(allProfiles.keys)")

        if waitingObservers.contains(.local) {
            waitingObservers.remove(.local)
        }

        if !excludedIds.isEmpty {
            pp_log_g(.App.profiles, .info, "Delete excluded profiles from repository: \(excludedIds)")
            Task {
                // XXX: ignore this published value
                try await repository.removeProfiles(withIds: Array(excludedIds))
            }
        }
    }

    func reloadRemoteProfiles(_ result: [Profile]) {
        objectWillChange.send()
        pp_log_g(.App.profiles, .info, "Reload remote profiles: \(result.map(\.id))")

        allRemoteProfiles = result.reduce(into: [:]) {
            $0[$1.id] = $1
        }
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
            pp_log_g(.App.profiles, .info, "Cancel ongoing remote import...")
            previousTask.cancel()
            await previousTask.value
            remoteImportTask = nil
        }

        pp_log_g(.App.profiles, .info, "Start importing remote profiles: \(profiles.map(\.id))")
        assert(profiles.count == Set(profiles.map(\.id)).count, "Remote repository must not have duplicates")

        pp_log_g(.App.profiles, .debug, "Local fingerprints:")
        let localFingerprints: [Profile.ID: UUID] = allProfiles.values.reduce(into: [:]) {
            $0[$1.id] = $1.attributes.fingerprint
            pp_log_g(.App.profiles, .debug, "\t\($1.id) = \($1.attributes.fingerprint.debugDescription)")
        }
        pp_log_g(.App.profiles, .debug, "Remote fingerprints:")
        let remoteFingerprints: [Profile.ID: UUID] = profiles.reduce(into: [:]) {
            $0[$1.id] = $1.attributes.fingerprint
            pp_log_g(.App.profiles, .debug, "\t\($1.id) = \($1.attributes.fingerprint.debugDescription)")
        }

        let remotelyDeletedIds = Set(allProfiles.keys).subtracting(Set(allRemoteProfiles.keys))
        let mirrorsRemoteRepository = mirrorsRemoteRepository

        remoteImportTask = Task.detached { [weak self] in
            guard let self else {
                return
            }

            var idsToRemove: [Profile.ID] = []
            if !remotelyDeletedIds.isEmpty {
                pp_log_g(.App.profiles, .info, "Will \(mirrorsRemoteRepository ? "delete" : "retain") local profiles not present in remote repository: \(remotelyDeletedIds)")
                if mirrorsRemoteRepository {
                    idsToRemove.append(contentsOf: remotelyDeletedIds)
                }
            }
            for remoteProfile in profiles {
                do {
                    guard await processor?.isIncluded(remoteProfile) ?? true else {
                        pp_log_g(.App.profiles, .info, "Will delete non-included remote profile \(remoteProfile.id)")
                        idsToRemove.append(remoteProfile.id)
                        continue
                    }
                    if let localFingerprint = localFingerprints[remoteProfile.id] {
                        guard let remoteFingerprint = remoteFingerprints[remoteProfile.id],
                              remoteFingerprint != localFingerprint else {
                            pp_log_g(.App.profiles, .info, "Skip re-importing local profile \(remoteProfile.id)")
                            continue
                        }
                    }
                    pp_log_g(.App.profiles, .notice, "Import remote profile \(remoteProfile.id)...")
                    try await save(remoteProfile)
                } catch {
                    pp_log_g(.App.profiles, .error, "Unable to import remote profile: \(error)")
                }
                guard !Task.isCancelled else {
                    pp_log_g(.App.profiles, .info, "Cancelled import of remote profiles: \(profiles.map(\.id))")
                    return
                }
            }

            pp_log_g(.App.profiles, .notice, "Finished importing remote profiles, delete stale profiles: \(idsToRemove)")
            if !idsToRemove.isEmpty {
                do {
                    try await repository.removeProfiles(withIds: idsToRemove)
                } catch {
                    pp_log_g(.App.profiles, .error, "Unable to delete stale profiles: \(error)")
                }
            }

            // yield a little bit
            try? await Task.sleep(for: .milliseconds(100))
        }
        await remoteImportTask?.value
        remoteImportTask = nil
    }

    func reloadFilteredProfiles(with search: String) {
        objectWillChange.send()
        filteredProfiles = allProfiles
            .values
            .filter {
                if !search.isEmpty {
                    return $0.name.lowercased().contains(search.lowercased())
                }
                return true
            }
            .sorted(by: Profile.sorting)

        pp_log_g(.App.profiles, .notice, "Filter profiles with '\(search)' (\(filteredProfiles.count)): \(filteredProfiles.map(\.name))")
    }
}
