// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import AppABI
import AppABI_C
import CommonLibrary
import Observation

@MainActor @Observable
public final class ProfileObserver {
    // FIXME: ###, use UI.*
    private var localProfiles: [Profile.ID: Profile] { // FIXME: ###, expensive
        didSet {
            reloadFilteredProfiles(with: searchSubject.value)
        }
    }
    private var remoteProfileIds: Set<Profile.ID>
    private var requiredFeatures: [Profile.ID: Set<AppFeature>]
    private let searchSubject: CurrentValueStream<String>

    public private(set) var headers: [UI.ProfileHeader]
    public private(set) var isReady: Bool
    public var isRemoteImportingEnabled: Bool

    // FIXME: ###, wrap access to ProfileManager in ABI methods
    private var profileManager: ProfileManager!

    public init() {
        localProfiles = [:]
        remoteProfileIds = []
        requiredFeatures = [:]
        searchSubject = CurrentValueStream("")
        headers = []
        isReady = false
        isRemoteImportingEnabled = false

        observeEvents()
    }
}

// MARK: - Actions

extension ProfileObserver {
//    // To avoid dup/expensive tracking of localProfiles
//    public func profile(withId profileId: Profile.ID) async -> Profile? {
//        await profileManager.profile(withId: profileId)
//    }
//
//    public func save(_ originalProfile: Profile, isLocal: Bool = false, remotelyShared: Bool? = nil) async throws
//    public func remove(withId profileId: Profile.ID) async
//    public func remove(withIds profileIds: [Profile.ID]) async
//    public func eraseRemotelySharedProfiles() async throws
//    public func resaveAllProfiles() async
//    public func observeLocal() async throws
//    public func observeRemote(repository: ProfileRepository) async throws

    public func search(byName name: String) {
        searchSubject.send(name)
    }

    public func duplicate(profileWithId profileId: Profile.ID) async throws {
        guard let profile = localProfiles[profileId] else {
            return
        }
        var builder = profile.builder(withNewId: true)
        builder.name = firstUniqueName(from: profile.name)
        pp_log_g(.App.profiles, .notice, "Duplicate profile [\(profileId), \(profile.name)] -> [\(builder.id), \(builder.name)]...")
        let copy = try builder.build()

        try await profileManager.save(copy)
    }
}

// MARK: - State

extension ProfileObserver {
    public var hasProfiles: Bool {
        !headers.isEmpty
    }

    public func profile(withId profileId: Profile.ID) -> Profile? {
        localProfiles[profileId]
    }

    public func requiredFeatures(forProfileWithId profileId: Profile.ID) -> Set<AppFeature>? {
        requiredFeatures[profileId]
    }

    public var isSearching: Bool {
        !searchSubject.value.isEmpty
    }

    public func isRemotelyShared(profileWithId profileId: Profile.ID) -> Bool {
        remoteProfileIds.contains(profileId)
    }

    public func isAvailableForTV(profileWithId profileId: Profile.ID) -> Bool {
        profile(withId: profileId)?.attributes.isAvailableForTV == true
    }

    public func firstUniqueName(from name: String) -> String {
        let allNames = Set(localProfiles.values.map(\.name))
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

    public func onUpdate(_ event: psp_event) {
        print("onUpdate() called")
        // FIXME: ###, this will replace didChange.subscribe() after using ABI rather than ProfileManager
    }
}

private extension ProfileObserver {
    func observeEvents() {
        Task { [weak self] in
            guard let self else { return }
            for await event in profileManager.didChange.subscribe() {
                guard !Task.isCancelled else { return }
                switch event {
                case .ready:
                    isReady = true
                case .localProfiles(let profiles):
                    localProfiles = profiles
                case .remoteProfiles(let ids):
                    remoteProfileIds = ids
                case .requiredFeatures(let features):
                    requiredFeatures = features
                default:
                    break
                }
            }
        }
        Task { [weak self] in
            guard let self else { return }
            // FIXME: ###, debounce
            for await term in searchSubject.subscribe() {
                guard !Task.isCancelled else { return }
                reloadFilteredProfiles(with: term)
            }
        }
    }

    func reloadFilteredProfiles(with search: String) {
        headers = localProfiles
            .values
            .filter {
                if !search.isEmpty {
                    return $0.name.lowercased().contains(search.lowercased())
                }
                return true
            }
            .sorted(by: Profile.sorting)
            .map(\.uiHeader)
            // FIXME: ###, localized module types
//            processor?.preview(from: $0) ?? ProfilePreview($0)

//        pp_log_g(.App.profiles, .notice, "Filter profiles with '\(search)' (\(filteredProfiles.count)): \(filteredProfiles.map(\.name))")
    }
}

// MARK: - FIXME: ###

extension ProfileObserver {
    @discardableResult
    func new() async throws -> UI.ProfileHeader {
        try await abi.profileNew()
    }

    @discardableResult
    func new(fromURL url: String) async throws -> UI.ProfileHeader {
        // FIXME: ###
        //        let text = try String(contentsOf: url)
        let text = "{\"id\":\"imported-url\",\"name\":\"imported url\"}"
        return try await abi.profileImportText(text)
    }

    @discardableResult
    func new(fromText text: String) async throws -> UI.ProfileHeader {
        // FIXME: ###
        let text = "{\"id\":\"imported-text\",\"name\":\"imported text\"}"
        return try await abi.profileImportText(text)
    }
}
