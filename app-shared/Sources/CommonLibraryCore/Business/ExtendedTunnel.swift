// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

@preconcurrency import Partout

#if !PSP_CROSS
extension ExtendedTunnel: ObservableObject {}
#endif

@MainActor
public final class ExtendedTunnel {
    public static nonisolated let isManualKey = "isManual"

    public static nonisolated let appPreferences = "appPreferences"

    private let tunnel: Tunnel

    private let sysex: ExtensionInstaller?

    private let kvStore: KeyValueStore?

    private let processor: AppTunnelProcessor?

    private let interval: TimeInterval

    public nonisolated let didChange: PassthroughStream<UniqueID, ABI.TunnelEvent>

    private var subscriptions: [Task<Void, Never>]

    // TODO: #218, keep "last used profile" until .multiple
    public init(
        tunnel: Tunnel,
        sysex: ExtensionInstaller? = nil,
        kvStore: KeyValueStore? = nil,
        processor: AppTunnelProcessor? = nil,
        interval: TimeInterval
    ) {
        self.tunnel = tunnel
        self.sysex = sysex
        self.kvStore = kvStore
        self.processor = processor
        self.interval = interval
        didChange = PassthroughStream()
        subscriptions = []

        observeObjects()
    }
}

// MARK: - Actions

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
            throw ABI.AppError.interactiveLogin
        }
#if !PSP_CROSS
        var options: [String: NSObject] = [Self.isManualKey: true as NSNumber]
        if let preferences = kvStore?.preferences {
            let encodedPreferences = try JSONEncoder().encode(preferences)
            options[Self.appPreferences] = encodedPreferences as NSData
        }
#else
        // FIXME: #228, Cross sends no .isManualKey to startTunnel()
        var options: Sendable? = nil
#endif

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
                        throw ABI.AppError.systemExtension(result)
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

    public func currentLog(parameters: ABI.Constants.Log) async -> [ABI.AppLogLine] {
        guard let anyProfile = tunnel.activeProfiles.first?.value else {
            return []
        }
        let output = try? await tunnel.sendMessage(.debugLog(
            sinceLast: parameters.sinceLast,
            maxLevel: parameters.options.maxLevel
        ), to: anyProfile.id)
        switch output {
        case .debugLog(let log):
            return log.lines.map {
                ABI.AppLogLine(timestamp: $0.timestamp, message: $0.message)
            }
        default:
            return []
        }
    }
}

// MARK: - State

extension ExtendedTunnel {
    public func transfer(ofProfileId profileId: ABI.AppIdentifier) -> ABI.ProfileTransfer? {
        dataCount(ofProfileId: profileId)?.abiTransfer
    }

    public func lastError(ofProfileId profileId: ABI.AppIdentifier) -> ABI.AppError? {
        guard let code = lastErrorCode(ofProfileId: profileId) else { return nil }
        return ABI.AppError.partout(PartoutError(code))
    }
}

// MARK: - Observation

private extension ExtendedTunnel {
    func observeObjects() {
        let tunnelEvents = tunnel.activeProfilesStream.removeDuplicates()
        let tunnelSubscription = Task { [weak self] in
            guard let self else {
                return
            }
            for await newActiveProfiles in tunnelEvents {
                guard !Task.isCancelled else {
                    pp_log_g(.App.core, .debug, "Cancelled ExtendedTunnel.tunnelSubscription")
                    break
                }
#if !PSP_CROSS
                objectWillChange.send()
#endif

                // TODO: #218, keep "last used profile" until .multiple
                if let first = newActiveProfiles.first {
                    kvStore?.set(first.key.uuidString, forAppPreference: .lastUsedProfileId)
                }

                // Publish compound statuses
                didChange.send(.refresh(computedProfileInfos(from: newActiveProfiles)))
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
#if !PSP_CROSS
                objectWillChange.send()
#endif
                didChange.send(.dataCount)

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
        guard let uuidString = kvStore?.string(forAppPreference: .lastUsedProfileId),
              let uuid = UUID(uuidString: uuidString) else {
            return nil
        }
        return TunnelActiveProfile(
            id: uuid,
            status: .inactive,
            onDemand: false
        )
    }

    func profileStatus(ofProfileId profileId: Profile.ID) -> ABI.AppProfile.Status {
        let status = status(ofProfileId: profileId)
        guard let environment = tunnel.environment(for: profileId) else {
            return status.abiStatus
        }
        return status.withEnvironment(environment).abiStatus
    }

    func computedProfileInfos(from activeProfiles: [Profile.ID: TunnelActiveProfile]) -> [ABI.AppIdentifier: ABI.AppProfile.Info] {
        var info = activeProfiles.mapValues {
            let profileStatus = profileStatus(ofProfileId: $0.id)
            return ABI.AppProfile.Info(id: $0.id, status: profileStatus, onDemand: $0.onDemand)
        }
        if info.isEmpty, let last = lastUsedProfile {
            info = [last.id: last.abiInfo]
        }
        return info
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

// MARK: - Deprecated

@available(*, deprecated, message: "#1594")
extension ExtendedTunnel {
    public var activeProfilesStream: AsyncStream<[Profile.ID: TunnelActiveProfile]> {
        tunnel.activeProfilesStream
    }

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
