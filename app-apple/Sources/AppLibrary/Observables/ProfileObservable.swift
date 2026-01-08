// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import Combine
import CommonLibrary
import Dispatch
import Observation

@MainActor @Observable
public final class ProfileObservable {
    private let abi: AppABIProfileProtocol & AppLogger

    private var allHeaders: [ABI.AppIdentifier: ABI.AppProfileHeader] {
        didSet {
            reloadHeaders(with: searchSubject.value)
        }
    }
    public private(set) var filteredHeaders: [ABI.AppProfileHeader]
    public private(set) var isReady: Bool
    public private(set) var isRemoteImportingEnabled: Bool
    private let searchSubject: CurrentValueSubject<String, Never>
    private var searchSubscription: AnyCancellable?

    public init(abi: AppABIProfileProtocol & AppLogger) {
        self.abi = abi

        allHeaders = [:]
        filteredHeaders = []
        isReady = false
        isRemoteImportingEnabled = false
        searchSubject = CurrentValueSubject("")
    }
}

// MARK: - Actions

extension ProfileObservable {
    // To avoid dup/expensive tracking of localProfiles
    public func profile(withId profileId: ABI.AppIdentifier) -> ABI.AppProfile? {
        abi.profile(withId: profileId)
    }

    public func save(_ profile: ABI.AppProfile, sharingFlag: ABI.ProfileSharingFlag? = nil) async throws {
        var partoutProfile = profile.native
        if sharingFlag == .tv {
            var builder = partoutProfile.builder()
            builder.attributes.isAvailableForTV = true
            partoutProfile = try builder.build()
        }
        try await abi.profileSave(ABI.AppProfile(native: partoutProfile), remotelyShared: sharingFlag != nil)
    }

    public func saveAll() async {
        await abi.profileSaveAll()
    }

    public func `import`(_ input: ABI.ProfileImporterInput, passphrase: String? = nil) async throws {
        switch input {
        case .contents(let filename, let data):
            try await abi.profileImportText(data, filename: filename, passphrase: passphrase)
        case .file(let url):
            try await abi.profileImportFile(url.filePath(), passphrase: passphrase)
        }
    }

    public func duplicate(profileWithId profileId: ABI.AppIdentifier) async throws {
        try await abi.profileDup(profileId)
    }

    public func search(byName name: String) {
        searchSubject.send(name)
    }

    public func remove(withId profileId: ABI.AppIdentifier) async {
        await abi.profileRemove(profileId)
    }

    public func remove(withIds profileIds: [ABI.AppIdentifier]) async {
        await abi.profileRemove(profileIds)
    }

    public func removeRemotelyShared() async throws {
        try await abi.profileRemoveAllRemote()
    }

//    public func setRemoteImportingEnabled(_ isEnabled: Bool) {
//        profileManager.isRemoteImportingEnabled = isEnabled
//    }
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

    public func isRemotelyShared(profileWithId profileId: ABI.AppIdentifier) -> Bool {
        abi.profileIsRemotelyShared(profileId)
    }

    public func sharingFlags(for profileId: ABI.AppIdentifier) -> [ABI.ProfileSharingFlag] {
        allHeaders[profileId]?.sharingFlags ?? []
    }

    public func requiredFeatures(forProfileWithId profileId: ABI.AppIdentifier) -> Set<ABI.AppFeature>? {
        allHeaders[profileId]?.requiredFeatures
    }

    public var isSearching: Bool {
        !searchSubject.value.isEmpty
    }

    func onUpdate(_ event: ABI.ProfileEvent) {
        abi.log(.core, .debug, "ProfileObservable.onUpdate(): \(event)")
        switch event {
        case .ready:
            isReady = true
        case .refresh(let headers):
            allHeaders = headers
//        case .changeRemoteImport:
//            // Later, set this property directly on ProfileObservable
//            isRemoteImportingEnabled = profileManager.isRemoteImportingEnabled
//            break
        default:
            break
        }
    }
}

private extension ProfileObservable {
    func observeEvents(debounce: Int = 200) {
        // No need for observeLocal/observeRemote, done by AppContext/ABI
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

        abi.log(.profiles, .notice, "Filter profiles with '\(search)' (\(filteredHeaders.count)): \(filteredHeaders.map(\.name))")
    }
}
