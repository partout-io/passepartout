// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import AppABI
import AppABI_C
import Foundation
import Observation

@MainActor @Observable
final class ProfileObserver {
    private(set) var headers: [ProfileHeaderUI]

    init() {
        headers = []
        refresh()
    }

    func refresh() {
        headers = abi.profileGetHeaders()
    }

    @discardableResult
    func new() async throws -> ProfileHeaderUI {
        try await abi.profileNew()
    }

    @discardableResult
    func new(fromURL url: URL) async throws -> ProfileHeaderUI {
        // FIXME: ###
        //        let text = try String(contentsOf: url)
        let text = "{\"id\":\"imported-url\",\"name\":\"imported url\"}"
        return try await abi.profileImportText(text)
    }

    @discardableResult
    func new(fromText text: String) async throws -> ProfileHeaderUI {
        // FIXME: ###
        let text = "{\"id\":\"imported-text\",\"name\":\"imported text\"}"
        return try await abi.profileImportText(text)
    }

    func onUpdate() {
        print("onUpdate() called")
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
