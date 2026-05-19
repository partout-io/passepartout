// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

@preconcurrency import Partout

@MainActor @Observable
public final class TunnelObservable {
    public struct Logging {
        public let maxDebugLogLevel: DebugLog.Level
        public let sinceLast: Double
        public let formatter: LogFormatter

        public init(maxDebugLogLevel: DebugLog.Level, sinceLast: Double, formatter: LogFormatter) {
            self.maxDebugLogLevel = maxDebugLogLevel
            self.sinceLast = sinceLast
            self.formatter = formatter
        }
    }

    public enum Options {
        public static nonisolated let isManualKey = "isManual"

        public static nonisolated let appPreferences = "appPreferences"
    }

    public typealias WillInstallBlock = @Sendable (Profile, Bool, Bool) async throws -> Profile?

    private let tunnel: Tunnel

    private let kvStore: KeyValueStore?

    private let logging: Logging?

    private let willInstall: WillInstallBlock?

    public private(set) var activeProfiles: [Profile.ID: ABI.AppTunnelInfo]

    private var subscriptions: [Task<Void, Never>]

    private var pendingTasks: [Profile.ID: PendingTask]

    // TODO: #218, keep "last used profile" until .multiple
    public init(
        tunnel: Tunnel,
        kvStore: KeyValueStore? = nil,
        logging: Logging? = nil,
        willInstall: WillInstallBlock? = nil
    ) {
        self.tunnel = tunnel
        self.kvStore = kvStore
        self.logging = logging
        self.willInstall = willInstall
        activeProfiles = [:]
        subscriptions = []
        pendingTasks = [:]
    }

}

// MARK: - Actions

extension TunnelObservable {
    public func install(_ profile: Profile) async throws {
        pspLog(.core, .notice, "Install profile \(profile.id)...")
        try await installAndConnect(false, with: profile, force: false)
    }

    public func connect(to profile: Profile) async throws {
        try await connect(to: profile, force: false)
    }

    public func connect(to profile: Profile, force: Bool) async throws {
        pspLog(.core, .notice, "Connect to profile \(profile.id)...")
        try await installAndConnect(true, with: profile, force: force)
    }

    private func installAndConnect(_ connect: Bool, with preProfile: Profile, force: Bool) async throws {
        let profile = try await willInstall?(preProfile, connect, force) ?? preProfile
        var options: [String: NSObject] = [Options.isManualKey: true as NSNumber]
        if let preferences = kvStore?.preferences {
            let encodedPreferences = try ABI.encode(preferences)
            options[Options.appPreferences] = encodedPreferences as NSData
        }
        try await tunnel.install(profile, connect: connect, options: options)
    }

    public func disconnect(from profileId: Profile.ID) async throws {
        pspLog(.core, .notice, "Disconnect...")
        try await tunnel.disconnect(from: profileId)
    }

    public func currentLog() async -> [String] {
        guard let logging else { return [] }
        return await currentLog(logging: logging).map {
            logging.formatter.formattedLog(timestamp: $0.timestamp, message: $0.message)
        }
    }

    private func currentLog(logging: Logging) async -> [ABI.LogLine] {
        var maxLevel = logging.maxDebugLogLevel
        if kvStore?.preferences.extensiveLogging == true {
            maxLevel = .debug
        }
        // TODO: #218, handle multiple profiles
        guard let firstProfileId = tunnel.snapshots.first?.key else {
            return []
        }
        let output = try? await tunnel.sendMessage(.debugLog(
            sinceLast: logging.sinceLast,
            maxLevel: maxLevel
        ), to: firstProfileId)
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

    public func tunnelStatus(for profileId: Profile.ID) -> TunnelStatus {
        activeProfiles[profileId]?.tunnelStatus ?? .inactive
    }

    public func transfer(for profileId: Profile.ID) -> ABI.ProfileTransfer? {
        activeProfiles[profileId]?.transfer
    }

    public func lastErrorCode(for profileId: Profile.ID) -> PartoutError.Code? {
        activeProfiles[profileId]?.lastErrorCode
    }

    public func openVPNServerConfiguration(for profileId: Profile.ID) async -> OpenVPN.Configuration? {
        await value(forKey: TunnelEnvironmentKeys.OpenVPN.serverConfiguration, ofProfileId: profileId)
    }

    private func value<T>(forKey key: TunnelEnvironmentKey<T>, ofProfileId profileId: Profile.ID) async -> T? where T: Decodable {
        await tunnel.environment(for: profileId)?.environmentValue(forKey: key)
    }
}

// MARK: - Observation

extension TunnelObservable {
    public func observeObjects() {
        let tunnelEvents = tunnel.snapshotsStream.removeDuplicates()
        let tunnelSubscription = Task { [weak self] in
            for await snapshots in tunnelEvents {
                guard let self else { return }
                guard !Task.isCancelled else { break }
                // Copy locally for sync access
                let newActiveProfiles = activeProfiles.with(
                    snapshots: snapshots,
                    lastUsedProfile: lastUsedProfile
                )
                // TODO: #218, keep "last used profile" until .multiple
                if let first = snapshots.first {
                    kvStore?.set(first.key.uuidString, forAppPreference: .lastUsedProfileId)
                }
                // Publish compound info
                if newActiveProfiles != activeProfiles {
                    activeProfiles = newActiveProfiles
                }
            }
            pspLog(.core, .debug, "Tunnel snapshots subscription terminated")
        }
        subscriptions = [tunnelSubscription]
    }

    public func onUpdate(_ event: ABI.Event) {
        guard case .mixed(let mixedEvent) = event else { return }
        guard case .shouldReconnect(let reconnectEvent) = mixedEvent else { return }
        let profile = reconnectEvent.profile

        let status = tunnelStatus(for: profile.id)
        guard [.active, .activating].contains(status) else {
            pspLog(.core, .debug, "\tConnection is not active (\(status)), do nothing")
            return
        }

        pendingTasks[profile.id]?.cancel()
        let pendingTask = PendingTask()
        pendingTasks[profile.id] = pendingTask
        pendingTask.task = Task { [weak self, weak pendingTask] in
            guard let self else { return }
            defer {
                if pendingTasks[profile.id] === pendingTask {
                    pendingTasks[profile.id] = nil
                }
            }
            do {
                pspLog(.core, .info, "\tReconnect profile \(profile.id)")
                try await disconnect(from: profile.id)
                guard !Task.isCancelled else { return }
                do {
                    try await connect(to: profile)
                } catch ABI.AppError.interactiveLogin {
                    pspLog(.core, .info, "\tProfile \(profile.id) is interactive, do not reconnect")
                } catch is CancellationError {
                    return
                } catch {
                    pspLog(.core, .error, "\tUnable to reconnect profile \(profile.id): \(error)")
                }
            } catch is CancellationError {
                return
            } catch {
                pspLog(.core, .error, "\tUnable to reinstate connection on save profile \(profile.id): \(error)")
            }
        }
    }
}

private final class PendingTask {
    var task: Task<Void, Never>?

    func cancel() {
        task?.cancel()
    }
}

// MARK: - Internal state

private extension TunnelObservable {
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
        lastUsedProfile: TunnelSnapshot?
    ) -> Self {
        var info = snapshots.mapValues {
            $0.abiInfo()
        }
        if info.isEmpty, let last = lastUsedProfile {
            info = [last.id: last.abiInfo()]
        }
        return info
    }
}
