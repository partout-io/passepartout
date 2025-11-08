// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import AppABI
import AppABI_C
import Observation

@MainActor @Observable
final class TunnelObserver: ABIObserver {
    private(set) var statuses: [UI.Identifier: UI.TunnelStatus]

    init() {
        statuses = [:]
        refresh()
    }

    func refresh() {
        statuses = abi.tunnelGetAll()
    }

    func status(for profileId: UI.Identifier) -> UI.TunnelStatus {
        statuses[profileId] ?? .disconnected
    }

    func setEnabled(_ enabled: Bool, profileId: UI.Identifier) {
        abi.tunnelSetEnabled(enabled, profileId: profileId)
    }

    func onUpdate(_ event: psp_event) {
        print("onUpdate() called")
        refresh()
    }

    // MARK: - Actions

//    public func install(_ profile: Profile) async throws
//    public func connect(with profile: Profile, force: Bool = false) async throws
//    public func disconnect(from profileId: Profile.ID) async throws
//    public func currentLog(parameters: Constants.Log) async -> [String]

    // MARK: - State

//    public var activeProfile: TunnelActiveProfile?
//    public var activeProfiles: [Profile.ID: TunnelActiveProfile]
//    public var activeProfilesStream: AsyncStream<[Profile.ID: TunnelActiveProfile]>
//    public func isActiveProfile(withId profileId: Profile.ID) -> Bool
//    public func status(ofProfileId profileId: Profile.ID) -> TunnelStatus
//    public func connectionStatus(ofProfileId profileId: Profile.ID) -> TunnelStatus
//    public func dataCount(ofProfileId profileId: Profile.ID) -> DataCount?
//    public func lastErrorCode(ofProfileId profileId: Profile.ID) -> PartoutError.Code?
//    public func value<T>(forKey key: TunnelEnvironmentKey<T>, ofProfileId profileId: Profile.ID) -> T?
}
