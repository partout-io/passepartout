// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonUtils
import Foundation

// FIXME: ###, Keep MainActor until observers
@MainActor
public final class ExtendedTunnel: ObservableObject {
    public static nonisolated let isManualKey = "isManual"

    public static nonisolated let appPreferences = "appPreferences"

    private let tunnel: Tunnel

    private let sysex: SystemExtensionManager?

    private let kvManager: KeyValueManager?

    private let processor: AppTunnelProcessor?

    private let interval: TimeInterval

    private var subscriptions: [Task<Void, Never>]

    // TODO: #218, keep "last used profile" until .multiple
    public init(
        tunnel: Tunnel,
        sysex: SystemExtensionManager? = nil,
        kvManager: KeyValueManager? = nil,
        processor: AppTunnelProcessor? = nil,
        interval: TimeInterval
    ) {
        self.tunnel = tunnel
        self.sysex = sysex
        self.kvManager = kvManager
        self.processor = processor
        self.interval = interval
        subscriptions = []

        observeObjects()
    }
}

// MARK: - Public interface

extension ExtendedTunnel {
    public func install(_ profile: Profile) async throws {
        pp_log_g(.App.core, .notice, "Install profile \(profile.id)...")
        try await installAndConnect(false, with: profile, force: false)
    }

    public func connect(with profile: Profile, force: Bool = false) async throws {
        pp_log_g(.App.core, .notice, "Connect to profile \(profile.id)...")
        try await installAndConnect(true, with: profile, force: force)
    }

    private func installAndConnect(_ connect: Bool, with profile: Profile, force: Bool) async throws {
        let newProfile = try await processedProfile(profile)
        if connect && !force && newProfile.isInteractive {
            throw AppError.interactiveLogin
        }
        var options: [String: NSObject] = [Self.isManualKey: true as NSNumber]
        if let preferences = kvManager?.preferences {
            let encodedPreferences = try JSONEncoder().encode(preferences)
            options[Self.appPreferences] = encodedPreferences as NSData
        }

#if os(macOS)
        if let sysex {
            if sysex.currentResult == .success {
                pp_log_g(.App.core, .info, "System Extension: already installed")
            } else {
                pp_log_g(.App.core, .info, "System Extension: install...")
                do {
                    let result = try await sysex.install()
                    switch result {
                    case .success:
                        break
                    default:
                        throw AppError.systemExtension(result)
                    }
                    pp_log_g(.App.core, .info, "System Extension: installation result is \(result)")
                } catch {
                    pp_log_g(.App.core, .error, "System Extension: installation error: \(error)")
                }
            }
        }
#endif

        try await tunnel.install(
            newProfile,
            connect: connect,
            options: options,
            title: processedTitle
        )
    }

    public func disconnect(from profileId: Profile.ID) async throws {
        pp_log_g(.App.core, .notice, "Disconnect...")
        try await tunnel.disconnect(from: profileId)
    }

    public func currentLog(parameters: Constants.Log) async -> [String] {
        guard let anyProfile = tunnel.activeProfiles.first?.value else {
            return []
        }
        let output = try? await tunnel.sendMessage(.debugLog(
            sinceLast: parameters.sinceLast,
            maxLevel: parameters.options.maxLevel
        ), to: anyProfile.id)
        switch output {
        case .debugLog(let log):
            return log.lines.map(parameters.formatter.formattedLine)
        default:
            return []
        }
    }
}

extension ExtendedTunnel {
#if os(iOS) || os(tvOS)
    public var activeProfile: TunnelActiveProfile? {
        tunnel.activeProfile
    }
#endif
    public var activeProfiles: [Profile.ID: TunnelActiveProfile] {
        guard !tunnel.activeProfiles.isEmpty else {
            if let last = lastUsedProfile {
                return [last.id: last]
            }
            return [:]
        }
        return tunnel.activeProfiles
    }

    public var activeProfilesStream: AsyncStream<[Profile.ID: TunnelActiveProfile]> {
        tunnel.activeProfilesStream
    }

    public func isActiveProfile(withId profileId: Profile.ID) -> Bool {
        tunnel.activeProfiles.keys.contains(profileId)
    }

    public func status(ofProfileId profileId: Profile.ID) -> TunnelStatus {
        activeProfiles[profileId]?.status ?? .inactive
    }

    public func connectionStatus(ofProfileId profileId: Profile.ID) -> TunnelStatus {
        let status = status(ofProfileId: profileId)
        guard let environment = tunnel.environment(for: profileId) else {
            return status
        }
        return status.withEnvironment(environment)
    }

    public func dataCount(ofProfileId profileId: Profile.ID) -> DataCount? {
        tunnel
            .environment(for: profileId)?
            .environmentValue(forKey: TunnelEnvironmentKeys.dataCount)
    }

    public func lastErrorCode(ofProfileId profileId: Profile.ID) -> PartoutError.Code? {
        tunnel
            .environment(for: profileId)?
            .environmentValue(forKey: TunnelEnvironmentKeys.lastErrorCode)
    }

    public func value<T>(forKey key: TunnelEnvironmentKey<T>, ofProfileId profileId: Profile.ID) -> T? where T: Decodable {
        tunnel
            .environment(for: profileId)?
            .environmentValue(forKey: key)
    }
}

// MARK: - Observation

private extension ExtendedTunnel {
    func observeObjects() {
        let tunnelSubscription = Task { [weak self] in
            guard let self else {
                return
            }
            for await newActiveProfiles in tunnel.activeProfilesStream.removeDuplicates() {
                guard !Task.isCancelled else {
                    pp_log_g(.App.core, .debug, "Cancelled ExtendedTunnel.tunnelSubscription")
                    break
                }
                objectWillChange.send()

                // TODO: #218, keep "last used profile" until .multiple
                if let first = newActiveProfiles.first {
                    kvManager?.set(first.key.uuidString, forAppPreference: .lastUsedProfileId)
                }
            }
        }

        let timerSubscription = Task { [weak self] in
            while true {
                guard let self else {
                    return
                }
                guard !Task.isCancelled else {
                    pp_log_g(.App.core, .debug, "Cancelled ExtendedTunnel.timerSubscription")
                    break
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
    var processedTitle: @Sendable (Profile) -> String {
        if let processor {
            return {
                processor.title(for: $0)
            }
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

// TODO: #218, keep "last used profile" until .multiple
private extension ExtendedTunnel {
    var lastUsedProfile: TunnelActiveProfile? {
        guard let uuidString = kvManager?.string(forAppPreference: .lastUsedProfileId),
              let uuid = UUID(uuidString: uuidString) else {
            return nil
        }
        return TunnelActiveProfile(
            id: uuid,
            status: .inactive,
            onDemand: false
        )
    }
}

extension TunnelStatus {
    func withEnvironment(_ environment: TunnelEnvironmentReader) -> TunnelStatus {
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
