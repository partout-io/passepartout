// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import Combine
import CommonLibrary
import Dispatch
import Foundation
import Observation

@MainActor @Observable
public final class ProfileObservable {
    private let logger: AppLogger
    private let profileManager: ProfileManager

    private var allHeaders: [ABI.AppIdentifier: ABI.AppProfileHeader] {
        didSet {
            reloadHeaders(with: searchSubject.value)
        }
    }
    public private(set) var filteredHeaders: [ABI.AppProfileHeader]
    public private(set) var isReady: Bool
    public private(set) var isRemoteImportingEnabled: Bool
    private var eventSubscription: AnyCancellable?
    private let searchSubject: CurrentValueSubject<String, Never>
    private var searchSubscription: AnyCancellable?

    public init(logger: AppLogger, profileManager: ProfileManager) {
        self.logger = logger
        self.profileManager = profileManager

        allHeaders = [:]
        filteredHeaders = []
        isReady = false
        isRemoteImportingEnabled = false
        searchSubject = CurrentValueSubject("")

        observeEvents()
    }
}

// MARK: - Actions

extension ProfileObservable {

    // To avoid dup/expensive tracking of localProfiles
    public func profile(withId profileId: ABI.AppIdentifier) -> ABI.AppProfile? {
        profileManager.profile(withId: profileId)
    }

    public func save(_ profile: ABI.AppProfile, isLocal: Bool = false, sharingFlag: ABI.ProfileSharingFlag? = nil) async throws {
        try await profileManager.save(profile.native, isLocal: isLocal, remotelyShared: sharingFlag != nil)
    }

    public func `import`(_ input: ABI.ProfileImporterInput, sharingFlag: ABI.ProfileSharingFlag? = nil) async throws {
        try await profileManager.import(input, sharingFlag: sharingFlag)
    }

    public func duplicate(profileWithId profileId: ABI.AppIdentifier) async throws {
        try await profileManager.duplicate(profileWithId: profileId)
    }

    public func search(byName name: String) {
        searchSubject.send(name)
    }

    public func remove(withId profileId: ABI.AppIdentifier) async {
        await profileManager.remove(withId: profileId)
    }

    public func remove(withIds profileIds: [ABI.AppIdentifier]) async {
        await profileManager.remove(withIds: profileIds)
    }

    public func removeRemotelyShared() async throws {
        try await profileManager.eraseRemotelySharedProfiles()
    }

    public func resaveAllProfiles() async {
        await profileManager.resaveAllProfiles()
    }

    public func setRemoteImportingEnabled(_ isEnabled: Bool) {
        profileManager.isRemoteImportingEnabled = isEnabled
    }
}

// MARK: - State

extension ProfileObservable {
    public var hasProfiles: Bool {
        !filteredHeaders.isEmpty
    }

    public func requiredFeatures(forProfileWithId profileId: ABI.AppIdentifier) -> Set<ABI.AppFeature>? {
        allHeaders[profileId]?.requiredFeatures
    }

    public var isSearching: Bool {
        !searchSubject.value.isEmpty
    }

//    public func onUpdate(_ event: ABI.Event) {
//        guard case .profiles(let profileEvent) = event else {
//            return
//        }
//        print("ProfileObserver.onUpdate()")
//        switch profileEvent {
//        case .ready:
//            isReady = true
//        case .refresh(let headers):
//            allHeaders = headers
//        }
//    }
}

private extension ProfileObservable {
    func observeEvents(debounce: Int = 200) {
        // No need for observeLocal/observeRemote, done by AppContext/ABI

        eventSubscription = profileManager
            .didChange
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in
                guard let self else { return }
                switch $0 {
                case .ready:
                    isReady = true
                case .refresh(let headers):
                    allHeaders = headers
                case .changeRemoteImport:
                    // Later, set this property directly on ProfileObservable
                    isRemoteImportingEnabled = profileManager.isRemoteImportingEnabled
                default:
                    break
                }
            }

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
            // FIXME: #1594, localized module types
//            processor?.preview(from: $0) ?? ABI.ProfilePreview($0)

        logger.log(.profiles, .notice, "Filter profiles with '\(search)' (\(filteredHeaders.count)): \(filteredHeaders.map(\.name))")
    }
}
