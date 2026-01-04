// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonLibrary
import Observation

@MainActor @Observable
public final class TunnelObservable {
    private let abi: AppABIProtocol

    public private(set) var activeProfiles: [ABI.AppIdentifier: ABI.AppProfile.Info]
    public private(set) var transfers: [ABI.AppIdentifier: ABI.ProfileTransfer]
    private var subscription: Task<Void, Never>?

    public init(abi: AppABIProtocol) {
        self.abi = abi
        activeProfiles = [:]
        transfers = [:]
    }
}

// MARK: - Actions

extension TunnelObservable {
    public func connect(to profileId: ABI.AppIdentifier, force: Bool = false) async throws {
        try await abi.tunnelConnect(to: profileId, force: force)
    }

    public func connect(to profile: ABI.AppProfile, force: Bool = false) async throws {
        try await abi.tunnelConnect(to: profile, force: force)
    }

//    public func reconnect(to profileId: ABI.AppIdentifier) async throws {
//        try await abi.tunnelReconnect(to: profileId)
//    }

    public func disconnect(from profileId: ABI.AppIdentifier) async throws {
        try await abi.tunnelDisconnect(from: profileId)
    }

    public func currentLog() async -> [String] {
        await abi.tunnelCurrentLog().map {
            abi.formattedLog(timestamp: $0.timestamp, message: $0.message)
        }
    }
}

// MARK: - State

extension TunnelObservable {
    public var activeProfile: ABI.AppProfile.Info? {
        activeProfiles.first?.value
    }

    public func isActiveProfile(withId profileId: ABI.AppIdentifier) -> Bool {
        activeProfiles.keys.contains(profileId)
    }

    public func status(for profileId: ABI.AppIdentifier) -> ABI.AppProfile.Status {
        activeProfiles[profileId]?.status ?? .disconnected
    }

    public func lastError(for profileId: ABI.AppIdentifier) -> ABI.AppError? {
        abi.tunnelLastError(ofProfileId: profileId)
    }

    func onUpdate(_ event: ABI.TunnelEvent) {
//        abi.log(.core, .debug, "TunnelObservable.onUpdate(): \(event)")
        switch event {
        case .refresh(let active):
            abi.log(.core, .debug, "TunnelObservable.onUpdate(): \(event)")
            activeProfiles = active
        case .dataCount:
            transfers = activeProfiles.compactMapValues {
                abi.tunnelTransfer(ofProfileId: $0.id)
            }
        }
    }
}
