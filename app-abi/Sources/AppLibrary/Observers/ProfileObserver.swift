// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import AppABI
import CommonABI_C
import Combine
import CommonABI
import Dispatch
import Foundation
import Observation

@MainActor @Observable
public final class ProfileObserver {
    private let abi: ABIProtocol

    private var allHeaders: [ABI.Identifier: ABI.ProfileHeader] {
        didSet {
            reloadHeaders(with: searchSubject.value)
        }
    }
    public private(set) var filteredHeaders: [ABI.ProfileHeader]
    public private(set) var isReady: Bool
    public var isRemoteImportingEnabled: Bool

    private let searchSubject: CurrentValueSubject<String, Never>
    private var searchSubscription: AnyCancellable?

    public init(abi: ABIProtocol) {
        self.abi = abi

        allHeaders = [:]
        filteredHeaders = []
        isReady = false
        isRemoteImportingEnabled = false

        searchSubject = CurrentValueSubject("")

        observeEvents()
    }
}

// MARK: - Actions

extension ProfileObserver {
    //    // To avoid dup/expensive tracking of localProfiles
    //    public func profile(withId profileId: ABI.Identifier) async -> Profile? {
    //        await profileManager.profile(withId: profileId)
    //    }
    //
    //    public func resaveAllProfiles() async

    //    public func save(_ originalProfile: Profile, isLocal: Bool = false, remotelyShared: Bool? = nil) async throws

    public func new() async throws {
        try await abi.profileNew(named: "lorem ipsum")
    }

    public func new(fromURL url: URL) async throws {
        let text = try String(contentsOf: url)
        try await abi.profileImportText(text)
    }

    public func new(fromText text: String) async throws {
        try await abi.profileImportText(text)
    }

    public func duplicate(profileWithId profileId: ABI.Identifier) async throws {
        try await abi.profileDup(profileId)
    }

    public func search(byName name: String) {
        searchSubject.send(name)
    }

    public func remove(withId profileId: ABI.Identifier) async {
        await abi.profileRemove(profileId)
    }

    public func remove(withIds profileIds: [ABI.Identifier]) async {
        await abi.profileRemove(profileIds)
    }

    public func removeRemotelyShared() async throws {
        try await abi.profileRemoveAllRemote()
    }
}

// MARK: - State

extension ProfileObserver: ABIObserver {
    public var hasProfiles: Bool {
        !filteredHeaders.isEmpty
    }

//    public func profile(withId profileId: ABI.Identifier) -> ABI.Profile? {
//        localProfiles[profileId]
//    }

    public func requiredFeatures(forProfileWithId profileId: ABI.Identifier) -> Set<ABI.AppFeature>? {
        allHeaders[profileId]?.requiredFeatures
    }

    public var isSearching: Bool {
        !searchSubject.value.isEmpty
    }

    public func onUpdate(_ event: ABI.Event) {
        guard case .profiles(let profileEvent) = event else {
            return
        }
        print("ProfileObserver.onUpdate()")
        switch profileEvent {
        case .ready:
            isReady = true
        case .refresh(let headers):
            allHeaders = headers
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
    }

    func reloadHeaders(with search: String) {
        filteredHeaders = allHeaders
            .map(\.value)
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
