// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonLibrary
import Foundation

@MainActor @Observable
public final class TunnelObservable {
    private let logger: AppLogger
    private let extendedTunnel: ExtendedTunnel

    public private(set) var activeProfiles: [ABI.AppIdentifier: ABI.AppProfile.Info]
    public private(set) var transfers: [ABI.AppIdentifier: ABI.ProfileTransfer]
    private var subscription: Task<Void, Never>?

    public init(logger: AppLogger, extendedTunnel: ExtendedTunnel) {
        self.logger = logger
        self.extendedTunnel = extendedTunnel
        activeProfiles = [:]
        transfers = [:]

        observeEvents()
    }
}

// MARK: - Actions

extension TunnelObservable {
    public func connect(to profile: ABI.AppProfile, force: Bool = false) async throws {
        try await extendedTunnel.connect(with: profile.native, force: force)
    }

//    public func reconnect(to profileId: ABI.AppIdentifier) async throws {
//        try await abi.tunnelReconnect(to: profileId)
//    }

    public func disconnect(from profileId: ABI.AppIdentifier) async throws {
        try await extendedTunnel.disconnect(from: profileId)
    }

    public func currentLog(parameters: ABI.Constants.Log) async -> [String] {
        await extendedTunnel.currentLog(parameters: parameters)
    }

//    public func onUpdate(_ event: ABI.Event) {
//        guard case .tunnel(let tunnelEvent) = event else {
//            return
//        }
//        print("TunnelObserver.onUpdate()")
//        switch tunnelEvent {
//        case .refresh:
//            break
//        }
//    }
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
        extendedTunnel.lastError(ofProfileId: profileId)
    }
}

private extension TunnelObservable {
    func observeEvents() {
        let tunnelEvents = extendedTunnel.didChange.subscribe()
        subscription = Task { [weak self] in
            guard let self else { return }
            for await event in tunnelEvents {
                switch event {
                case .refresh(let active):
                    activeProfiles = active
                case .dataCount:
                    transfers = activeProfiles.compactMapValues {
                        self.extendedTunnel.transfer(ofProfileId: $0.id)
                    }
                }
            }
        }
    }
}
