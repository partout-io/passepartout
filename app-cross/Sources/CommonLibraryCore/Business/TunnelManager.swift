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

    private var latestInfo: [Profile.ID: ABI.AppTunnelInfo]? {
        didSet {
            didChange.send(.refresh(.init(active: latestInfo ?? [:])))
        }
    }

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
        latestInfo = nil
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

    public func currentLog(parameters: ABI.AppConstants.Log) async -> [ABI.LogLine] {
        var maxLevel = parameters.options.maxDebugLogLevel
        if kvStore?.preferences.extensiveLogging == true {
            maxLevel = .debug
        }
        let output = try? await tunnel.sendMessage(.debugLog(
            sinceLast: parameters.sinceLast,
            maxLevel: maxLevel
        ))
        switch output {
        case .debugLog(let log):
            return log.lines.map {
                ABI.LogLine(timestamp: $0.timestamp, message: $0.message)
            }
        default:
            return []
        }
    }
}

// MARK: - State

extension TunnelManager {
    public func isActiveProfile(withId profileId: Profile.ID) -> Bool {
        latestInfo?.keys.contains(profileId) ?? false
    }

    public func status(ofProfileId profileId: Profile.ID) -> ABI.AppProfileStatus {
        latestInfo?[profileId]?.status ?? .disconnected
    }

    public func tunnelStatus(ofProfileId profileId: Profile.ID) -> TunnelStatus {
        latestInfo?[profileId]?.tunnelStatus ?? .inactive
    }

    public func transfer(ofProfileId profileId: Profile.ID) -> ABI.ProfileTransfer? {
        latestInfo?[profileId]?.transfer
    }

    public func lastErrorCode(ofProfileId profileId: Profile.ID) -> PartoutError.Code? {
        latestInfo?[profileId]?.lastErrorCode
    }

    public func value<T>(forKey key: TunnelEnvironmentKey<T>, ofProfileId profileId: Profile.ID) async -> T? where T: Decodable {
        await tunnel.environment(for: profileId)?.environmentValue(forKey: key)
    }
}

// MARK: - Observation

extension TunnelManager {
    public func observeObjects() -> AsyncStream<ABI.TunnelEvent> {
        let tunnelEvents = tunnel.snapshotsStream.removeDuplicates()
        let tunnelSubscription = Task { [weak self] in
            for await snapshots in tunnelEvents {
                guard let self else { return }
                guard !Task.isCancelled else {
                    pspLog(.core, .debug, "Cancelled TunnelManager.tunnelSubscription")
                    break
                }
                // Copy locally for sync access
                let latestEnvironments = await tunnel.allEnvironments()
                let newInfo = latestInfo?.with(
                    snapshots: snapshots,
                    lastUsedProfile: lastUsedProfile,
                    environments: latestEnvironments
                ) ?? [:]
                // TODO: #218, keep "last used profile" until .multiple
                if let first = snapshots.first {
                    kvStore?.set(first.key.uuidString, forAppPreference: .lastUsedProfileId)
                }
                // Publish compound info
                if newInfo != latestInfo {
                    latestInfo = newInfo
                }
            }
        }

        let timerSubscription = Task { [weak self] in
            while true {
                guard let self else { return }
                guard !Task.isCancelled else {
                    pspLog(.core, .debug, "Cancelled TunnelManager.timerSubscription")
                    break
                }
                let latestEnvironments = await tunnel.allEnvironments()
                let newInfo = latestInfo?.updated(with: latestEnvironments) ?? [:]
                if newInfo != latestInfo {
                    latestInfo = newInfo
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

// MARK: - Internal state

private extension TunnelManager {
    // TODO: #218, keep "last used profile" until .multiple
    var lastUsedProfile: TunnelSnapshot? {
        guard let uuidString = kvStore?.string(forAppPreference: .lastUsedProfileId),
              let uuid = UniqueID(uuidString: uuidString) else {
            return nil
        }
        return TunnelSnapshot(
            id: uuid,
            isEnabled: false,
            status: .inactive,
            onDemand: false
        )
    }
}

private extension Dictionary where Key == Profile.ID, Value == ABI.AppTunnelInfo {
    func with(
        snapshots: [Profile.ID: TunnelSnapshot],
        lastUsedProfile: TunnelSnapshot?,
        environments: [Profile.ID: TunnelEnvironmentReader],
    ) -> Self {
        var info = snapshots.mapValues {
            $0.abiInfo(withEnvironment: environments[$0.id])
        }
        if info.isEmpty, let last = lastUsedProfile {
            info = [last.id: last.abiInfo(withEnvironment: nil)]
        }
        return info
    }

    func updated(with environments: [Profile.ID: TunnelEnvironmentReader]) -> Self {
        mapValues {
            guard let env = environments[$0.id] else { return $0 }
            return $0.with(environment: env)
        }
    }
}
