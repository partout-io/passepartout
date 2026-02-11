// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonLibrary
import Observation

@MainActor @Observable
public final class TunnelObservable {
    private let abi: AppABITunnelProtocol
    private let formatter: LogFormatter?

    public private(set) var activeProfiles: [Profile.ID: ABI.AppProfileInfo]
    public private(set) var transfers: [Profile.ID: ABI.ProfileTransfer]
    private var subscription: Task<Void, Never>?

    public init(abi: AppABITunnelProtocol, formatter: LogFormatter?) {
        self.abi = abi
        self.formatter = formatter
        activeProfiles = [:]
        transfers = [:]
    }
}

// MARK: - Actions

extension TunnelObservable {
//    public func connect(to profileId: Profile.ID, force: Bool = false) async throws {
//        try await abi.connect(to: profileId, force: force)
//    }

    public func connect(to profile: Profile, force: Bool = false) async throws {
        try await abi.connect(to: profile, force: force)
    }

//    public func reconnect(to profileId: Profile.ID) async throws {
//        try await abi.reconnect(to: profileId)
//    }

    public func disconnect(from profileId: Profile.ID) async throws {
        try await abi.disconnect(from: profileId)
    }

    public func currentLog() async -> [String] {
        await abi.currentLog().map {
            formatter?.formattedLog(timestamp: $0.timestamp, message: $0.message) ?? $0.message
        }
    }
}

// MARK: - State

extension TunnelObservable {
    public var activeProfile: ABI.AppProfileInfo? {
        activeProfiles.first?.value
    }

    public func isActiveProfile(withId profileId: Profile.ID) -> Bool {
        activeProfiles.keys.contains(profileId)
    }

    public func status(for profileId: Profile.ID) -> ABI.AppProfileStatus {
        activeProfiles[profileId]?.status ?? .disconnected
    }

    public func lastError(for profileId: Profile.ID) -> ABI.AppError? {
        abi.lastError(ofProfileId: profileId)
    }

    public func openVPNServerConfiguration(for profileId: Profile.ID) -> OpenVPN.Configuration? {
        abi.environmentValue(for: .openVPNServerConfiguration, ofProfileId: profileId) as? OpenVPN.Configuration
    }

    func onUpdate(_ event: ABI.TunnelEvent) {
//        pspLog(.core, .debug, "TunnelObservable.onUpdate(): \(event)")
        switch event {
        case .refresh(let active):
            pspLog(.core, .debug, "TunnelObservable.onUpdate(): \(event)")
            activeProfiles = active
        case .dataCount:
            transfers = activeProfiles.compactMapValues {
                abi.transfer(ofProfileId: $0.id)
            }
        }
    }
}
