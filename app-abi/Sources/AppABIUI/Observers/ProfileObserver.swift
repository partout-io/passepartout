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
    private var allProfiles: [Profile.ID: Profile]
    private var allRemoteProfiles: [Profile.ID: Profile]
    private var filteredProfiles: [Profile]
    private var requiredFeatures: [Profile.ID: Set<AppFeature>]

    public private(set) var isReady: Bool

    // FIXME: ###, wrap in ABI
    private var profileManager: ProfileManager!

    public init() {
        allProfiles = [:]
        allRemoteProfiles = [:]
        filteredProfiles = []
        requiredFeatures = [:]
        isReady = false

        observeEvents()
        refresh()
    }

    // MARK: - Actions

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

    // MARK: - State

    //    private var allProfiles: [Profile.ID: Profile]
    //    private var allRemoteProfiles: [Profile.ID: Profile]
    //    private var filteredProfiles: [Profile]
    //    public let didChange: PassthroughSubject<Event, Never>
    //    @Published private var requiredFeatures: [Profile.ID: Set<AppFeature>]
    //    @Published public var isRemoteImportingEnabled = false
    //
    //    public var isReady: Bool
    //    public var hasProfiles: Bool
    //    public var previews: [ProfilePreview]
    //    public func profile(withId profileId: Profile.ID) -> Profile?
    //    public var isSearching: Bool
    //    public func requiredFeatures(forProfileWithId profileId: Profile.ID) -> Set<AppFeature>?
    //    public func isRemotelyShared(profileWithId profileId: Profile.ID) -> Bool
    //    public func isAvailableForTV(profileWithId profileId: Profile.ID) -> Bool
}

extension ProfileObserver {
    public var hasProfiles: Bool {
        !filteredProfiles.isEmpty
    }

    public var previews: [UI.ProfileHeader] {
        // FIXME: ###, filter profile previews by processor in manager
//        filteredProfiles.map {
//            processor?.preview(from: $0) ?? ProfilePreview($0)
//        }
        filteredProfiles.map(\.uiPreview)
    }

    public func profile(withId profileId: Profile.ID) -> Profile? {
        allProfiles[profileId]
    }

    public func requiredFeatures(forProfileWithId profileId: Profile.ID) -> Set<AppFeature>? {
        requiredFeatures[profileId]
    }

//    public var isSearching: Bool {
//        !searchSubject.value.isEmpty
//    }
//
//    public func search(byName name: String) {
//        searchSubject.send(name)
//    }
}

extension ProfileObserver: ABIObserver {
    public func refresh() {
//        headers = abi.profileGetHeaders()
    }

    public func onUpdate(_ event: psp_event) {
        print("onUpdate() called")
        refresh()
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
                default:
                    break
                }
            }
        }
    }
}

// TODO: ###
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
