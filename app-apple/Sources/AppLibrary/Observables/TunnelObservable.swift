// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonLibrary
import Observation

@MainActor @Observable
public final class TunnelObservable {
    private let abi: AppABITunnelProtocol
    private let formatter: LogFormatter?

    public private(set) var activeProfiles: [Profile.ID: ABI.AppTunnelInfo]
    private var subscription: Task<Void, Never>?

    public init(abi: AppABITunnelProtocol, formatter: LogFormatter?) {
        self.abi = abi
        self.formatter = formatter
        activeProfiles = [:]
    }
}

// MARK: - Actions

extension TunnelObservable {
//    public func connect(to profileId: Profile.ID, force: Bool = false) async throws {
//        try await abi.connect(to: profileId, force: force)
//    }

    public func connect(to profile: Profile, force: Bool = false) async throws {
        do {
            try await abi.connect(to: profile, force: force)
        } catch let ppError as PartoutError {
            switch ppError.code {
            case .Providers.missingEntity:
                throw ABI.AppError.missingProviderEntity
            default:
                throw ppError
            }
        }
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
    public var activeProfile: ABI.AppTunnelInfo? {
        activeProfiles.first?.value
    }

    public func isActiveProfile(withId profileId: Profile.ID) -> Bool {
        activeProfiles.keys.contains(profileId)
    }

    public func status(for profileId: Profile.ID) -> ABI.AppProfileStatus {
        activeProfiles[profileId]?.status ?? .disconnected
    }

    public func transfer(for profileId: Profile.ID) -> ABI.ProfileTransfer? {
        activeProfiles[profileId]?.transfer
    }

    public func lastError(for profileId: Profile.ID) -> ABI.AppError? {
        activeProfiles[profileId]?.lastErrorCode.map {
            ABI.AppError.partout(PartoutError($0))
        }
    }

    public func openVPNServerConfiguration(for profileId: Profile.ID) async -> OpenVPN.Configuration? {
        await abi.environmentValue(for: .openVPNServerConfiguration, ofProfileId: profileId) as? OpenVPN.Configuration
    }

    func onUpdate(_ event: ABI.TunnelEvent) {
//        pspLog(.core, .debug, "TunnelObservable.onUpdate(): \(event)")
        switch event {
        case .refresh(let payload):
            pspLog(.core, .debug, "TunnelObservable.onUpdate(): \(event)")
            activeProfiles = payload.active
        }
    }
}
