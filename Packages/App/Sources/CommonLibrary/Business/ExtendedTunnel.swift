//
//  ExtendedTunnel.swift
//  Passepartout
//
//  Created by Davide De Rosa on 9/7/24.
//  Copyright (c) 2025 Davide De Rosa. All rights reserved.
//
//  https://github.com/passepartoutvpn
//
//  This file is part of Passepartout.
//
//  Passepartout is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  Passepartout is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with Passepartout.  If not, see <http://www.gnu.org/licenses/>.
//

import Foundation

@MainActor
public final class ExtendedTunnel: ObservableObject {
    public static nonisolated let isManualKey = "isManual"

    private let kvStore: KeyValueManager?

    private let tunnel: Tunnel

    private let environment: TunnelEnvironment

    private let processor: AppTunnelProcessor?

    private let interval: TimeInterval

    public func value<T>(forKey key: TunnelEnvironmentKey<T>) -> T? where T: Decodable {
        environment.environmentValue(forKey: key)
    }

    public private(set) var lastErrorCode: PartoutError.Code? {
        didSet {
            pp_log(.app, .info, "ExtendedTunnel.lastErrorCode -> \(lastErrorCode?.rawValue ?? "nil")")
        }
    }

    public private(set) var dataCount: DataCount?

    private var subscriptions: [Task<Void, Never>]

    public init(
        kvStore: KeyValueManager? = nil,
        tunnel: Tunnel,
        environment: TunnelEnvironment,
        processor: AppTunnelProcessor? = nil,
        interval: TimeInterval
    ) {
        self.kvStore = kvStore
        self.tunnel = tunnel
        self.environment = environment
        self.processor = processor
        self.interval = interval
        subscriptions = []

        observeObjects()
    }
}

// MARK: - Public interface

extension ExtendedTunnel {
    public var status: TunnelStatus {
        tunnel.status
    }

    public var connectionStatus: TunnelStatus {
        tunnel.status.withEnvironment(environment)
    }
}

extension ExtendedTunnel {
    public var currentProfile: TunnelCurrentProfile? {
        tunnel.currentProfile ?? lastUsedProfile
    }

    public var currentProfiles: [Profile.ID: TunnelCurrentProfile] {
        tunnel.currentProfiles
    }

    public var currentProfileStream: AsyncStream<TunnelCurrentProfile?> {
        AsyncStream { [weak self] continuation in
            Task { [weak self] in
                guard let self else {
                    continuation.finish()
                    return
                }
                for await current in tunnel.currentProfileStream {
                    guard !Task.isCancelled else {
                        pp_log(.app, .debug, "Cancelled ExtendedTunnel.currentProfileStream (returned)")
                        break
                    }
                    continuation.yield(current ?? lastUsedProfile)
                }
                continuation.finish()
            }
        }
    }

    public func install(_ profile: Profile) async throws {
        pp_log(.app, .notice, "Install profile \(profile.id)...")
        let newProfile = try await processedProfile(profile)
        try await tunnel.install(
            newProfile,
            connect: false,
            options: .init(values: [Self.isManualKey: true as NSNumber]),
            title: processedTitle
        )
    }

    public func connect(with profile: Profile, force: Bool = false) async throws {
        pp_log(.app, .notice, "Connect to profile \(profile.id)...")
        let newProfile = try await processedProfile(profile)
        if !force && newProfile.isInteractive {
            throw AppError.interactiveLogin
        }
        try await tunnel.install(
            newProfile,
            connect: true,
            options: .init(values: [Self.isManualKey: true as NSNumber]),
            title: processedTitle
        )
    }

    public func disconnect() async throws {
        pp_log(.app, .notice, "Disconnect...")
        try await tunnel.disconnect()
    }

    public func currentLog(parameters: Constants.Log) async -> [String] {
        let output = try? await tunnel.sendMessage(.localLog(
            sinceLast: parameters.sinceLast,
            maxLevel: parameters.options.maxLevel
        ))
        switch output {
        case .debugLog(let log):
            return log.lines.map(parameters.formatter.formattedLine)

        default:
            return []
        }
    }
}

// MARK: - Observation

private extension ExtendedTunnel {
    func observeObjects() {
        let tunnelSubscription = Task { [weak self] in
            guard let self else {
                return
            }
            for await current in tunnel.currentProfileStream.removeDuplicates() {
                guard !Task.isCancelled else {
                    pp_log(.app, .debug, "Cancelled ExtendedTunnel.currentProfileStream (observed)")
                    break
                }
                await MainActor.run { [weak self] in
                    guard let self else {
                        return
                    }

                    // update last used profile
                    if let id = current?.id {
                        kvStore?.set(id.uuidString, forKey: AppPreference.lastUsedProfileId.key)
                    }

                    // follow status updates
                    switch current?.status ?? .inactive {
                    case .active:
                        break
                    case .activating:
                        lastErrorCode = nil
                        dataCount = nil
                    default:
                        lastErrorCode = value(forKey: TunnelEnvironmentKeys.lastErrorCode)
                        dataCount = nil
                    }

                    objectWillChange.send()
                }
            }
        }

        let timerSubscription = Task { [weak self] in
            while true {
                guard let self else {
                    return
                }
                guard !Task.isCancelled else {
                    pp_log(.app, .debug, "Cancelled ExtendedTunnel.timerTask")
                    break
                }
                if let lastErrorCode = value(forKey: TunnelEnvironmentKeys.lastErrorCode),
                    lastErrorCode != self.lastErrorCode {
                    self.lastErrorCode = lastErrorCode
                }
                if tunnel.status == .active {
                    dataCount = value(forKey: TunnelEnvironmentKeys.dataCount)
                }
                objectWillChange.send()

                try? await Task.sleep(interval: interval)
            }
        }

        subscriptions = [tunnelSubscription, timerSubscription]
    }
}

// MARK: - Processing

private extension ExtendedTunnel {
    var processedTitle: (Profile) -> String {
        if let processor {
            return processor.title
        }
        return \.name
    }

    func processedProfile(_ profile: Profile) async throws -> Profile {
        if let processor {
            return try await processor.willInstall(profile)
        }
        return profile
    }
}

// MARK: - Helpers

private extension ExtendedTunnel {
    var lastUsedProfile: TunnelCurrentProfile? {
        guard let uuidString = kvStore?.string(forKey: AppPreference.lastUsedProfileId.key),
              let uuid = UUID(uuidString: uuidString) else {
            return nil
        }
        return TunnelCurrentProfile(
            id: uuid,
            status: .inactive,
            onDemand: false
        )
    }
}

extension TunnelStatus {
    func withEnvironment(_ environment: TunnelEnvironment) -> TunnelStatus {
        var status = self
        if status == .active, let connectionStatus = environment.environmentValue(forKey: TunnelEnvironmentKeys.connectionStatus) {
            switch connectionStatus {
            case .connecting:
                status = .activating
            case .connected:
                status = .active
            case .disconnecting:
                status = .deactivating
            case .disconnected:
                status = .inactive
            }
        }
        return status
    }
}
