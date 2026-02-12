// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import Combine
import CommonLibrary
import Dispatch
import Observation

@MainActor @Observable
public final class ProfileObservable {
    private let abi: AppABIProfileProtocol

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
        self.abi = abi
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
    // To avoid dup/expensive tracking of localProfiles
    public func profile(withId profileId: Profile.ID) -> Profile? {
        abi.profile(withId: profileId)
    }

    public func header(withId profileId: Profile.ID) -> ABI.AppProfileHeader? {
        allHeaders[profileId]
    }

    public func save(_ profile: Profile, sharingFlag: ABI.ProfileSharingFlag? = nil) async throws {
        var copy = profile
        if sharingFlag == .tv {
            var builder = copy.builder()
            builder.attributes.isAvailableForTV = true
            copy = try builder.build()
        }
        try await abi.save(copy, remotelyShared: sharingFlag != nil)
    }

    public func saveAll() async {
        await abi.saveAll()
    }

    public func `import`(_ input: ABI.ProfileImporterInput, passphrase: String? = nil) async throws {
        switch input {
        case .contents(let filename, let data):
            try await abi.importText(data, filename: filename, passphrase: passphrase)
        case .file(let url):
            try await abi.importFile(url.filePath(), passphrase: passphrase)
        }
    }

    public func duplicate(profileWithId profileId: Profile.ID) async throws {
        try await abi.duplicate(profileId)
    }

    public func search(byName name: String) {
        searchSubject.send(name)
    }

    public func remove(withId profileId: Profile.ID) async {
        await abi.remove(profileId)
    }

    public func remove(withIds profileIds: [Profile.ID]) async {
        await abi.remove(profileIds)
    }

    public func removeRemotelyShared() async throws {
        try await abi.removeAllRemote()
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
        case .refresh(let headers):
            allHeaders = headers
        case .changeRemoteImporting(let isEnabled):
            isRemoteImportingEnabled = isEnabled
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
