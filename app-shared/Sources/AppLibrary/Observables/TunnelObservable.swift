// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonLibrary
import Observation

@MainActor @Observable
public final class TunnelObservable {
    private let logger: AppLogger
    private let extendedTunnel: ExtendedTunnel

    public private(set) var activeProfiles: [AppIdentifier: AppProfile.Info]
    public private(set) var transfers: [AppIdentifier: ProfileTransfer]
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
    public func connect(to profile: AppProfile, force: Bool = false) async throws {
        try await extendedTunnel.connect(with: profile.native, force: force)
    }

//    public func reconnect(to profileId: AppIdentifier) async throws {
//        try await abi.tunnelReconnect(to: profileId)
//    }

    public func disconnect(from profileId: AppIdentifier) async throws {
        try await extendedTunnel.disconnect(from: profileId)
    }

    public func currentLog(parameters: Constants.Log) async -> [String] {
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
    public var activeProfile: AppProfile.Info? {
        activeProfiles.first?.value
    }

    public func isActiveProfile(withId profileId: AppIdentifier) -> Bool {
        activeProfiles.keys.contains(profileId)
    }

    public func status(for profileId: AppIdentifier) -> AppProfile.Status {
        activeProfiles[profileId]?.status ?? .disconnected
    }

    public func lastError(for profileId: AppIdentifier) -> AppError? {
        extendedTunnel.lastError(ofProfileId: profileId)
    }
}

private extension TunnelObservable {
    func observeEvents() {
        subscription = Task { [weak self] in
            guard let self else { return }
            for await event in extendedTunnel.didChange.subscribe() {
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
