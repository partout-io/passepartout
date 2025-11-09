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
    public private(set) var headers: [UI.ProfileHeader]
    private var localProfiles: [Profile.ID: Profile] // FIXME: ###, expensive
    private var remoteProfileIds: Set<Profile.ID>
    private var requiredFeatures: [Profile.ID: Set<AppFeature>]

    public private(set) var isReady: Bool
    public var isRemoteImportingEnabled = false

    // FIXME: ###, wrap access to ProfileManager in ABI methods
    private var profileManager: ProfileManager!

    public init() {
        headers = []
        localProfiles = [:]
        remoteProfileIds = []
        requiredFeatures = [:]
        isReady = false

        observeEvents()
    }
}

// MARK: - Actions

extension ProfileObserver {
    // To avoid dup/expensive tracking of localProfiles
//    public func profile(withId profileId: Profile.ID) async -> Profile? {
//        await profileManager.profile(withId: profileId)
//    }

//    public func search(byName name: String)
//    public func reloadRequiredFeatures()
//    public func save(_ originalProfile: Profile, isLocal: Bool = false, remotelyShared: Bool? = nil) async throws
//    public func remove(withId profileId: Profile.ID) async
//    public func remove(withIds profileIds: [Profile.ID]) async
//    public func eraseRemotelySharedProfiles() async throws
//    public func firstUniqueName(from name: String) -> String
//    public func duplicate(profileWithId profileId: Profile.ID) async throws
//    public func resaveAllProfiles() async
//    public func observeLocal() async throws
//    public func observeRemote(repository: ProfileRepository) async throws
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

//    public var isSearching: Bool {
//        !searchSubject.value.isEmpty
//    }
//
//    public func isRemotelyShared(profileWithId profileId: Profile.ID) -> Bool
//
//    public func isAvailableForTV(profileWithId profileId: Profile.ID) -> Bool

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
                case .filteredPreviews(let previews):
                    headers = previews.map(\.uiHeader)
                case .requiredFeatures(let features):
                    requiredFeatures = features
                default:
                    break
                }
            }
        }
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
