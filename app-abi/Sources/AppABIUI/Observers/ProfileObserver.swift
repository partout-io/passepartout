// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import AppABI
import AppABI_C
import Combine
import CommonUI
import Dispatch
import Foundation
import Observation

@MainActor @Observable
public final class ProfileObserver {
//    private let abi: ABIProtocol

    private var localProfiles: [UI.Identifier: UI.Profile] {
        didSet {
            reloadHeaders(with: searchSubject.value)
        }
    }
    private var requiredFeatures: [UI.Identifier: Set<UI.AppFeature>]
    public private(set) var headers: [UI.ProfileHeader]
    public private(set) var isReady: Bool
    public var isRemoteImportingEnabled: Bool

    private let searchSubject: CurrentValueSubject<String, Never>
    private var searchSubscription: AnyCancellable?

    public init() {//abi: ABIProtocol) {
//        self.abi = abi

        localProfiles = [:]
        requiredFeatures = [:]
        headers = []
        isReady = false
        isRemoteImportingEnabled = false

        searchSubject = CurrentValueSubject("")

        observeEvents()
    }
}

// MARK: - Actions

extension ProfileObserver {
//    // To avoid dup/expensive tracking of localProfiles
//    public func profile(withId profileId: UI.Identifier) async -> Profile? {
//        await profileManager.profile(withId: profileId)
//    }
//
//    public func save(_ originalProfile: Profile, isLocal: Bool = false, remotelyShared: Bool? = nil) async throws
//    public func remove(withId profileId: UI.Identifier) async
//    public func remove(withIds profileIds: [UI.Identifier]) async
//    public func eraseRemotelySharedProfiles() async throws
//    public func resaveAllProfiles() async
//    public func observeLocal() async throws
//    public func observeRemote(repository: ProfileRepository) async throws

    public func new() async throws {
        let name = firstUniqueName(from: "lorem ipsum")
        try await abi.profileNew(named: name)
    }

    public func new(fromURL url: URL) async throws {
        // FIXME: ###
//        let text = try String(contentsOf: url)
        let text = "{\"id\":\"imported-url\",\"name\":\"imported url\",\"moduleTypes\":[],\"fingerprint\":\"\",\"sharingFlags\":[]}"
        try await abi.profileImportText(text)
    }

    public func new(fromText text: String) async throws {
        // FIXME: ###
        let text = "{\"id\":\"imported-text\",\"name\":\"imported text\",\"moduleTypes\":[],\"fingerprint\":\"\",\"sharingFlags\":[]}"
        try await abi.profileImportText(text)
    }

    public func search(byName name: String) {
        searchSubject.send(name)
    }

    public func duplicate(profileWithId profileId: UI.Identifier) async throws {
        guard var profile = localProfiles[profileId] else {
            return
        }
        profile.renewId()
        profile.name = firstUniqueName(from: profile.name)
//        pp_log_g(.App.profiles, .notice, "Duplicate profile [\(profileId), \(profile.name)] -> [\(builder.id), \(builder.name)]...")
        try await abi.profileSave(profile)
    }
}

// MARK: - State

extension ProfileObserver: ABIObserver {
    public var hasProfiles: Bool {
        !headers.isEmpty
    }

    public func profile(withId profileId: UI.Identifier) -> UI.Profile? {
        localProfiles[profileId]
    }

    public func requiredFeatures(forProfileWithId profileId: UI.Identifier) -> Set<UI.AppFeature>? {
        requiredFeatures[profileId]
    }

    public var isSearching: Bool {
        !searchSubject.value.isEmpty
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

    public func onUpdate(_ event: UI.Event) {
        guard case .profiles(let profileEvent) = event else {
            return
        }
        print("ProfileObserver.onUpdate()")
        switch profileEvent {
        case .ready:
            isReady = true
        case .refresh(let profiles):
            localProfiles = profiles
        case .requiredFeatures(let features):
            requiredFeatures = features
        }
    }
}

private extension ProfileObserver {
    func observeEvents(debounce: Int = 200) {
        searchSubscription = searchSubject
            .debounce(for: .milliseconds(debounce), scheduler: DispatchQueue.main)
            .sink { [weak self] in
                self?.reloadHeaders(with: $0)
            }
        Task {
            try await abi.profileObserveLocal()
        }
    }

    func reloadHeaders(with search: String) {
        headers = localProfiles
            .map(\.value.header)
            .filter {
                if !search.isEmpty {
                    return $0.name.lowercased().contains(search.lowercased())
                }
                return true
            }
            .sorted()
            // FIXME: ###, localized module types
//            processor?.preview(from: $0) ?? ProfilePreview($0)

//        pp_log_g(.App.profiles, .notice, "Filter profiles with '\(search)' (\(filteredProfiles.count)): \(filteredProfiles.map(\.name))")
    }
}
