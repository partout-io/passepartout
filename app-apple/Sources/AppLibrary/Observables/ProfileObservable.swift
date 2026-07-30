// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import Combine
import CommonLibrary
import Dispatch
import Observation

@MainActor @Observable
public final class ProfileObservable {
    private enum Backend {
        case abi(AppABIProfileProtocol)
        case manager(ProfileManager, registry: CodingRegistry)
    }

    private let backend: Backend

    private var allHeaders: [Profile.ID: ABI.AppProfileHeader] {
        didSet {
            reloadHeaders(with: searchSubject.value)
        }
    }
    public private(set) var filteredHeaders: [ABI.AppProfileHeader]
    public private(set) var isReady: Bool
    public private(set) var isRemoteImportingEnabled: Bool
    private let searchSubject: CurrentValueSubject<String, Never>
    private var searchSubscription: AnyCancellable?

    public init(abi: AppABIProfileProtocol, searchDebounce: Int = 200) {
        backend = .abi(abi)
        allHeaders = [:]
        filteredHeaders = []
        isReady = false
        isRemoteImportingEnabled = false
        searchSubject = CurrentValueSubject("")

        observeEvents(searchDebounce: searchDebounce)
    }

    public init(
        profileManager: ProfileManager,
        registry: CodingRegistry,
        searchDebounce: Int = 200
    ) {
        backend = .manager(profileManager, registry: registry)
        allHeaders = [:]
        filteredHeaders = []
        isReady = false
        isRemoteImportingEnabled = false
        searchSubject = CurrentValueSubject("")

        observeEvents(searchDebounce: searchDebounce)
    }
}

// MARK: - Actions

extension ProfileObservable {
    public func save(_ profile: Profile, sharingFlag: ABI.ProfileSharingFlag? = nil) async throws {
        var copy = profile
        if sharingFlag == .tv {
            var builder = copy.builder()
            builder.attributes.isAvailableForTV = true
            copy = try builder.build()
        }
        switch backend {
        case .abi(let abi):
            try await abi.save(copy, remotelyShared: sharingFlag != nil)
        case .manager(let profileManager, _):
            try await profileManager.save(
                copy,
                isLocal: true,
                remotelyShared: sharingFlag != nil
            )
        }
    }

    public func saveAll() async {
        switch backend {
        case .abi(let abi):
            await abi.saveAll()
        case .manager(let profileManager, _):
            await profileManager.resaveAllProfiles()
        }
    }

    public func `import`(_ input: ABI.ProfileImporterInput, passphrase: String? = nil) async throws {
        switch backend {
        case .abi(let abi):
            switch input {
            case .contents(let filename, let data):
                try await abi.importText(data, filename: filename, passphrase: passphrase)
            case .file(let url):
                try await abi.importFile(url.filePath(), passphrase: passphrase)
            }
        case .manager(let profileManager, let registry):
            let profile = try registry.importedProfile(
                from: input,
                passphrase: passphrase
            )
            try await profileManager.save(
                profile,
                isLocal: true,
                remotelyShared: nil
            )
        }
    }

    public func duplicate(profileWithId profileId: Profile.ID) async throws {
        switch backend {
        case .abi(let abi):
            try await abi.duplicate(profileId)
        case .manager(let profileManager, _):
            try await profileManager.duplicate(profileWithId: profileId)
        }
    }

    public func search(byName name: String) {
        searchSubject.send(name)
    }

    public func remove(withId profileId: Profile.ID) async {
        switch backend {
        case .abi(let abi):
            await abi.remove(profileId)
        case .manager(let profileManager, _):
            await profileManager.remove(withId: profileId)
        }
    }

    public func remove(withIds profileIds: [Profile.ID]) async {
        switch backend {
        case .abi(let abi):
            await abi.remove(profileIds)
        case .manager(let profileManager, _):
            await profileManager.remove(withIds: profileIds)
        }
    }

    public func removeRemotelyShared() async throws {
        switch backend {
        case .abi(let abi):
            try await abi.removeAllRemote()
        case .manager(let profileManager, _):
            try await profileManager.eraseRemotelySharedProfiles()
        }
    }

    public func removeAll() async {
        await remove(withIds: filteredHeaders.map(\.id))
    }
}

// MARK: - State

extension ProfileObservable {
    public var hasProfiles: Bool {
        !filteredHeaders.isEmpty
    }

    // DO USE headers for UI to react (locally observed)
    public func header(withId profileId: Profile.ID) -> ABI.AppProfileHeader? {
        allHeaders[profileId]
    }

    // Use full profiles for actions (manually pulled)
    public func profile(withId profileId: Profile.ID) -> Profile? {
        switch backend {
        case .abi(let abi):
            return abi.profile(withId: profileId)
        case .manager(let profileManager, _):
            return profileManager.profile(withId: profileId)
        }
    }

    public func firstUniqueName(from name: String) -> String {
        let allNames = Set(allHeaders.values.map(\.name))
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

    public func isRemotelyShared(profileWithId profileId: Profile.ID) -> Bool {
        allHeaders[profileId]?.sharingFlags.isEmpty == false
    }

    public func sharingFlags(for profileId: Profile.ID) -> [ABI.ProfileSharingFlag] {
        allHeaders[profileId]?.sharingFlags ?? []
    }

    public func requiredFeatures(forProfileWithId profileId: Profile.ID) -> Set<ABI.AppFeature>? {
        allHeaders[profileId]?.requiredFeatures
    }

    public var isSearching: Bool {
        !searchSubject.value.isEmpty
    }

    func onUpdate(_ event: ABI.ProfileEvent) {
        pspLog(.core, .debug, "ProfileObservable.onUpdate(): \(event)")
        switch event {
        case .ready:
            isReady = true
        case .refresh(let payload):
            allHeaders = payload.headers
        case .changeRemoteImporting(let payload):
            isRemoteImportingEnabled = payload.isImporting
        default:
            break
        }
    }
}

private extension ProfileObservable {
    func observeEvents(searchDebounce: Int) {
        // No need for observeLocal/observeRemote, done by AppContext/ABI
        searchSubscription = searchSubject
            .debounce(for: .milliseconds(searchDebounce), scheduler: DispatchQueue.main)
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

        pspLog(.profiles, .notice, "Filter profiles with '\(search)' (\(filteredHeaders.count)): \(filteredHeaders.map(\.name))")
    }
}
