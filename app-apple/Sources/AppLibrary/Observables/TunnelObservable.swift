// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonLibrary
import Observation

@MainActor @Observable
public final class TunnelObservable {
    private let abi: AppABITunnelProtocol
    private let logger: (AppLogger & LogFormatter)?

    public private(set) var activeProfiles: [ABI.AppIdentifier: ABI.AppProfile.Info]
    public private(set) var transfers: [ABI.AppIdentifier: ABI.ProfileTransfer]
    private var subscription: Task<Void, Never>?

    public init(abi: AppABITunnelProtocol, logger: (AppLogger & LogFormatter)?) {
        self.abi = abi
        self.logger = logger
        activeProfiles = [:]
        transfers = [:]
    }
}

// MARK: - Actions

extension TunnelObservable {
//    public func connect(to profileId: ABI.AppIdentifier, force: Bool = false) async throws {
//        try await abi.connect(to: profileId, force: force)
//    }

    public func connect(to profile: ABI.AppProfile, force: Bool = false) async throws {
        try await abi.connect(to: profile, force: force)
    }

//    public func reconnect(to profileId: ABI.AppIdentifier) async throws {
//        try await abi.reconnect(to: profileId)
//    }

    public func disconnect(from profileId: ABI.AppIdentifier) async throws {
        try await abi.disconnect(from: profileId)
    }

    public func currentLog() async -> [String] {
        await abi.currentLog().map {
            logger?.formattedLog(timestamp: $0.timestamp, message: $0.message) ?? $0.message
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
        abi.lastError(ofProfileId: profileId)
    }

    public func openVPNServerConfiguration(for profileId: ABI.AppIdentifier) -> OpenVPN.Configuration? {
        abi.environmentValue(for: .openVPNServerConfiguration, ofProfileId: profileId) as? OpenVPN.Configuration
    }

    func onUpdate(_ event: ABI.TunnelEvent) {
//        abi.log(.core, .debug, "TunnelObservable.onUpdate(): \(event)")
        switch event {
        case .refresh(let active):
            logger?.log(.core, .debug, "TunnelObservable.onUpdate(): \(event)")
            activeProfiles = active
        case .dataCount:
            transfers = activeProfiles.compactMapValues {
                abi.transfer(ofProfileId: $0.id)
            }
        }
    }
}
