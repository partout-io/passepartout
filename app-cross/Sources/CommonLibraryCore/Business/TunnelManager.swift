// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

@preconcurrency import Partout

@BusinessActor
public final class TunnelManager {
    public static nonisolated let isManualKey = "isManual"

    public static nonisolated let appPreferences = "appPreferences"

    private let tunnel: Tunnel

    private let extensionInstaller: ExtensionInstaller?

    private let kvStore: KeyValueStore?

    private let processor: AppTunnelProcessor?

    private let interval: TimeInterval

    private nonisolated let didChange: PassthroughStream<ABI.TunnelEvent>

    private var latestActiveProfiles: [Profile.ID: TunnelActiveProfile]

    private var latestEnvironments: [Profile.ID: TunnelEnvironmentReader]

    private var subscriptions: [Task<Void, Never>]

    // TODO: #218, keep "last used profile" until .multiple
    public nonisolated init(
        tunnel: Tunnel,
        extensionInstaller: ExtensionInstaller? = nil,
        kvStore: KeyValueStore? = nil,
        processor: AppTunnelProcessor? = nil,
        interval: TimeInterval
    ) {
        self.tunnel = tunnel
        self.extensionInstaller = extensionInstaller
        self.kvStore = kvStore
        self.processor = processor
        self.interval = interval
        didChange = PassthroughStream()
        latestActiveProfiles = [:]
        latestEnvironments = [:]
        subscriptions = []
    }
}

// MARK: - Actions

extension TunnelManager {
    public func install(_ profile: Profile) async throws {
        pspLog(.core, .notice, "Install profile \(profile.id)...")
        try await installAndConnect(false, with: profile, force: false)
    }

    public func connect(with profile: Profile, force: Bool = false) async throws {
        pspLog(.core, .notice, "Connect to profile \(profile.id)...")
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
        // Cross sends no .isManualKey to startTunnel()
        var options: Sendable?
#endif

#if os(macOS)
        if let extensionInstaller {
            if extensionInstaller.currentResult == .success {
                pspLog(.core, .info, "Extensions: already installed")
            } else {
                pspLog(.core, .info, "Extensions: install...")
                do {
                    let result = try await extensionInstaller.install()
                    switch result {
                    case .success:
                        break
                    default:
                        throw ABI.AppError.systemExtension(result)
                    }
                    pspLog(.core, .info, "Extensions: installation result is \(result)")
                } catch {
                    pspLog(.core, .error, "Extensions: installation error: \(error)")
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
        pspLog(.core, .notice, "Disconnect...")
        try await tunnel.disconnect(from: profileId)
    }

    public func currentLog(parameters: ABI.AppConstants.Log) async -> [ABI.AppLogLine] {
        let output = try? await tunnel.sendMessage(.debugLog(
            sinceLast: parameters.sinceLast,
            maxLevel: parameters.options.maxLevel
        ))
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

extension TunnelManager {
    public func isActiveProfile(withId profileId: Profile.ID) -> Bool {
        activeProfiles.keys.contains(profileId)
    }

    public func status(ofProfileId profileId: Profile.ID) -> TunnelStatus {
        activeProfiles[profileId]?.status ?? .inactive
    }

    public func transfer(ofProfileId profileId: Profile.ID) -> ABI.ProfileTransfer? {
        dataCount(ofProfileId: profileId)?.abiTransfer
    }

    public func lastError(ofProfileId profileId: Profile.ID) -> ABI.AppError? {
        guard let code = lastErrorCode(ofProfileId: profileId) else { return nil }
        return ABI.AppError.partout(PartoutError(code))
    }

    public func value<T>(forKey key: TunnelEnvironmentKey<T>, ofProfileId profileId: Profile.ID) -> T? where T: Decodable {
        latestEnvironments[profileId]?.environmentValue(forKey: key)
    }
}

// MARK: - Observation

extension TunnelManager {
    public func observeObjects() -> AsyncStream<ABI.TunnelEvent> {
        let tunnelEvents = tunnel.activeProfilesStream.removeDuplicates()
        let tunnelSubscription = Task { [weak self] in
            guard let self else { return }
            for await newActiveProfiles in tunnelEvents {
                guard !Task.isCancelled else {
                    pspLog(.core, .debug, "Cancelled TunnelManager.tunnelSubscription")
                    break
                }
                // Copy locally for sync access
                latestActiveProfiles = newActiveProfiles
                latestEnvironments = await tunnel.allEnvironments()
                // TODO: #218, keep "last used profile" until .multiple
                if let first = newActiveProfiles.first {
                    kvStore?.set(first.key.uuidString, forAppPreference: .lastUsedProfileId)
                }
                // Publish compound statuses
                didChange.send(.refresh(.init(
                    active: computedTunnelInfos(from: newActiveProfiles)
                )))
            }
        }

        let timerSubscription = Task { [weak self] in
            while true {
                guard let self else { return }
                guard !Task.isCancelled else {
                    pspLog(.core, .debug, "Cancelled TunnelManager.timerSubscription")
                    break
                }
                latestEnvironments = await tunnel.allEnvironments()
                if !latestEnvironments.isEmpty {
                    didChange.send(.dataCount())
                }
                try? await Task.sleep(interval: interval)
            }
        }

        subscriptions = [tunnelSubscription, timerSubscription]
        return didChange.subscribe()
    }
}

// MARK: - Processing

private extension TunnelManager {
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
private extension TunnelManager {
    var lastUsedProfile: TunnelActiveProfile? {
        guard let uuidString = kvStore?.string(forAppPreference: .lastUsedProfileId),
              let uuid = UniqueID(uuidString: uuidString) else {
            return nil
        }
        return TunnelActiveProfile(
            id: uuid,
            status: .inactive,
            onDemand: false
        )
    }

    func profileStatus(ofProfileId profileId: Profile.ID) -> ABI.AppTunnelStatus {
        let status = status(ofProfileId: profileId)
        guard let environment = latestEnvironments[profileId] else {
            return status.abiStatus
        }
        return status.withEnvironment(environment).abiStatus
    }

    func computedTunnelInfos(from activeProfiles: [Profile.ID: TunnelActiveProfile]) -> [Profile.ID: ABI.AppTunnelInfo] {
        var info = activeProfiles.mapValues {
            let profileStatus = profileStatus(ofProfileId: $0.id)
            return ABI.AppTunnelInfo(id: $0.id, status: profileStatus, onDemand: $0.onDemand)
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

// MARK: - Internal state

private extension TunnelManager {
    var activeProfiles: [Profile.ID: TunnelActiveProfile] {
        guard !latestActiveProfiles.isEmpty else {
            if let last = lastUsedProfile {
                return [last.id: last]
            }
            return [:]
        }
        return latestActiveProfiles
    }

    func connectionStatus(ofProfileId profileId: Profile.ID) -> TunnelStatus {
        let status = status(ofProfileId: profileId)
        guard let environment = latestEnvironments[profileId] else {
            return status
        }
        return status.withEnvironment(environment)
    }

    func dataCount(ofProfileId profileId: Profile.ID) -> DataCount? {
        latestEnvironments[profileId]?
            .environmentValue(forKey: TunnelEnvironmentKeys.dataCount)
    }

    func lastErrorCode(ofProfileId profileId: Profile.ID) -> PartoutError.Code? {
        latestEnvironments[profileId]?
            .environmentValue(forKey: TunnelEnvironmentKeys.lastErrorCode)
    }
}
