// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import AppABI
import CommonABI_C
import CommonABI
import Observation

@MainActor @Observable
public final class TunnelObserver: ABIObserver {
    private let abi: ABIProtocol

    private(set) var statuses: [ABI.Identifier: ABI.TunnelStatus]

    public init(abi: ABIProtocol) {
        self.abi = abi
        statuses = [:]
    }
}

// MARK: - Actions

extension TunnelObserver {
    public func connect(to profileId: ABI.Identifier, force: Bool = false) async throws {
        try await abi.tunnelConnect(to: profileId, force: force)
    }

//    public func reconnect(to profileId: ABI.Identifier) async throws {
//        try await abi.tunnelReconnect(to: profileId)
//    }

    public func disconnect(from profileId: ABI.Identifier) async throws {
        try await abi.tunnelDisconnect(from: profileId)
    }

    public func currentLog() async -> [String] {
        await abi.tunnelCurrentLog()
    }

    public func onUpdate(_ event: ABI.Event) {
        guard case .tunnel(let tunnelEvent) = event else {
            return
        }
        print("TunnelObserver.onUpdate()")
        switch tunnelEvent {
        case .refresh:
            break
        }
    }
}

// MARK: - State

extension TunnelObserver {
//    public var activeProfile: TunnelActiveProfile?
//    public var activeProfiles: [Profile.ID: TunnelActiveProfile]
//    public var activeProfilesStream: AsyncStream<[Profile.ID: TunnelActiveProfile]>
//    public func isActiveProfile(withId profileId: Profile.ID) -> Bool
//    public func status(ofProfileId profileId: Profile.ID) -> TunnelStatus
//    public func connectionStatus(ofProfileId profileId: Profile.ID) -> TunnelStatus
//    public func dataCount(ofProfileId profileId: Profile.ID) -> DataCount?
//    public func lastErrorCode(ofProfileId profileId: Profile.ID) -> PartoutError.Code?
//    public func value<T>(forKey key: TunnelEnvironmentKey<T>, ofProfileId profileId: Profile.ID) -> T?

    public func status(for profileId: ABI.Identifier) -> ABI.TunnelStatus {
        statuses[profileId] ?? .disconnected
    }
}
