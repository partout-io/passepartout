// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import AppABI
import AppABI_C
import Combine
import Dispatch
import Observation

@MainActor @Observable
public final class ProfileObserver {
//    private let abi: ABIProtocol

    private var localProfiles: [UI.Identifier: UI.Profile] { // FIXME: ###, expensive
        didSet {
            reloadHeaders(with: searchSubject.value)
        }
    }
    private var remoteProfileIds: Set<UI.Identifier>
    private var requiredFeatures: [UI.Identifier: Set<UI.AppFeature>]
    public private(set) var headers: [UI.ProfileHeader]
    public private(set) var isReady: Bool
    public var isRemoteImportingEnabled: Bool

    private let searchSubject: CurrentValueSubject<String, Never>
    private var searchSubscription: AnyCancellable?

    public init() {//abi: ABIProtocol) {
//        self.abi = abi

        localProfiles = [:]
        remoteProfileIds = []
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

extension ProfileObserver {
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

    public func isRemotelyShared(profileWithId profileId: UI.Identifier) -> Bool {
        remoteProfileIds.contains(profileId)
    }

    public func isAvailableForTV(profileWithId profileId: UI.Identifier) -> Bool {
//        profile(withId: profileId)?.attributes.isAvailableForTV == true
        profile(withId: profileId)?.sharingFlags.contains(.tv) == true
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
        guard event.area == PSPAreaProfile else { return }
        print("ProfileObserver.onUpdate()")
        let result = event.object?.assumingMemoryBound(to: ABIResult.self).pointee.value
        switch event.type {
        case PSPEventTypeProfileReady:
            isReady = true
        case PSPEventTypeProfileLocal:
            localProfiles = result as? [UI.Identifier: UI.Profile] ?? [:]
      case PSPEventTypeProfileRemote:
            remoteProfileIds = result as? Set<UI.Identifier> ?? []
        case PSPEventTypeProfileRequiredFeatures:
            requiredFeatures = result as? [UI.Identifier: Set<UI.AppFeature>] ?? [:]
        default:
            break
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
            .values
            .map(\.header)
//                $0.header uiHeader(sharingFlags: sharingFlags(for: $0.header.id))
//            }
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

    func sharingFlags(for profileId: UI.Identifier) -> [UI.ProfileSharingFlag] {
        if isRemotelyShared(profileWithId: profileId) {
            if isAvailableForTV(profileWithId: profileId) {
                return [.tv]
            } else {
                return [.shared]
            }
        }
        return []
    }
}

// MARK: - FIXME: ###

extension ProfileObserver {
    @discardableResult
    func new() async throws -> UI.ProfileHeader {
//        try await abi.profileNew()
        let profile = UI.Profile(name: "new")
        try await abi.profileSave(profile)
        return profile.header
    }

    @discardableResult
    func new(fromURL url: String) async throws -> UI.ProfileHeader {
        // FIXME: ###
//        let text = try String(contentsOf: url)
//        let text = "{\"id\":\"imported-url\",\"name\":\"imported url\",\"moduleTypes\":[],\"fingerprint\":\"\",\"sharingFlags\":[]}"
//        return try await abi.profileImportText(text)
        let profile = UI.Profile(name: url)
        try await abi.profileSave(profile)
        return profile.header
    }

    @discardableResult
    func new(fromText text: String) async throws -> UI.ProfileHeader {
        // FIXME: ###
//        let text = "{\"id\":\"imported-text\",\"name\":\"imported text\",\"moduleTypes\":[],\"fingerprint\":\"\",\"sharingFlags\":[]}"
//        return try await abi.profileImportText(text)
        let profile = UI.Profile(name: text)
        try await abi.profileSave(profile)
        return profile.header
    }
}
