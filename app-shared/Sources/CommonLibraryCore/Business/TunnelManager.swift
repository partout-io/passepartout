// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

@preconcurrency import Partout

@MainActor
public final class TunnelManager {
    public static nonisolated let isManualKey = "isManual"

    public static nonisolated let appPreferences = "appPreferences"

    private let tunnel: Tunnel

    private let extensionInstaller: ExtensionInstaller?

    private let kvStore: KeyValueStore?

    private let processor: AppTunnelProcessor?

    private let interval: TimeInterval

    public nonisolated let didChange: PassthroughStream<UniqueID, ABI.TunnelEvent>

    private var subscriptions: [Task<Void, Never>]

    // TODO: #218, keep "last used profile" until .multiple
    public init(
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
        subscriptions = []

        observeObjects()
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
        // FIXME: #228, Cross sends no .isManualKey to startTunnel()
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

extension TunnelManager {
    public func isActiveProfile(withId profileId: Profile.ID) -> Bool {
        tunnel.activeProfiles.keys.contains(profileId)
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
        tunnel
            .environment(for: profileId)?
            .environmentValue(forKey: key)
    }
}

// MARK: - Observation

private extension TunnelManager {
    func observeObjects() {
        let tunnelEvents = tunnel.activeProfilesStream.removeDuplicates()
        let tunnelSubscription = Task { [weak self] in
            guard let self else {
                return
            }
            for await newActiveProfiles in tunnelEvents {
                guard !Task.isCancelled else {
                    pspLog(.core, .debug, "Cancelled TunnelManager.tunnelSubscription")
                    break
                }
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
                    pspLog(.core, .debug, "Cancelled TunnelManager.timerSubscription")
                    break
                }
                didChange.send(.dataCount)
                try? await Task.sleep(interval: interval)
            }
        }

        subscriptions = [tunnelSubscription, timerSubscription]
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

    func profileStatus(ofProfileId profileId: Profile.ID) -> ABI.AppProfileStatus {
        let status = status(ofProfileId: profileId)
        guard let environment = tunnel.environment(for: profileId) else {
            return status.abiStatus
        }
        return status.withEnvironment(environment).abiStatus
    }

    func computedProfileInfos(from activeProfiles: [Profile.ID: TunnelActiveProfile]) -> [Profile.ID: ABI.AppProfileInfo] {
        var info = activeProfiles.mapValues {
            let profileStatus = profileStatus(ofProfileId: $0.id)
            return ABI.AppProfileInfo(id: $0.id, status: profileStatus, onDemand: $0.onDemand)
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
        guard !tunnel.activeProfiles.isEmpty else {
            if let last = lastUsedProfile {
                return [last.id: last]
            }
            return [:]
        }
        return tunnel.activeProfiles
    }

    func connectionStatus(ofProfileId profileId: Profile.ID) -> TunnelStatus {
        let status = status(ofProfileId: profileId)
        guard let environment = tunnel.environment(for: profileId) else {
            return status
        }
        return status.withEnvironment(environment)
    }

    func dataCount(ofProfileId profileId: Profile.ID) -> DataCount? {
        tunnel
            .environment(for: profileId)?
            .environmentValue(forKey: TunnelEnvironmentKeys.dataCount)
    }

    func lastErrorCode(ofProfileId profileId: Profile.ID) -> PartoutError.Code? {
        tunnel
            .environment(for: profileId)?
            .environmentValue(forKey: TunnelEnvironmentKeys.lastErrorCode)
    }
}
