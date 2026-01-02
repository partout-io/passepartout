// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

public final class TunnelABI: TunnelABIProtocol {
    public struct IAP: Sendable {
        let manager: IAPManager
        let verificationParameters: ABI.Constants.Tunnel.Verification.Parameters
        let usesRelaxedVerification: Bool

        public init(
            manager: IAPManager,
            verificationParameters: ABI.Constants.Tunnel.Verification.Parameters,
            usesRelaxedVerification: Bool
        ) {
            self.manager = manager
            self.verificationParameters = verificationParameters
            self.usesRelaxedVerification = usesRelaxedVerification
        }
    }

    private let appLogger: AppLogger
    private let daemon: ConnectionDaemon
    private let environment: TunnelEnvironment
    private let iap: IAP?
    private let logFormatter: LogFormatter
    private let originalProfile: ABI.AppProfile

    private var verifierSubscription: Task<Void, Error>?

    public init(
        appLogger: AppLogger,
        daemon: ConnectionDaemon,
        environment: TunnelEnvironment,
        iap: IAP?,
        logFormatter: LogFormatter,
        originalProfile: ABI.AppProfile
    ) {
        self.appLogger = appLogger
        self.daemon = daemon
        self.environment = environment
        self.iap = iap
        self.logFormatter = logFormatter
        self.originalProfile = originalProfile
    }

    public func start(isInteractive: Bool) async throws {
        try trackContext()

        do {
            // Check hold flag and hang the tunnel if set
            if environment.environmentValue(forKey: TunnelEnvironmentKeys.holdFlag) == true {
                appLogger.log(.core, .info, "Tunnel is on hold")
                guard isInteractive else {
                    appLogger.log(.core, .error, "Tunnel was started non-interactively, hang here")
                    return
                }
                appLogger.log(.core, .info, "Tunnel was started interactively, clear hold flag")
                environment.removeEnvironmentValue(forKey: TunnelEnvironmentKeys.holdFlag)
            }

            // Start the tunnel
            try await daemon.start()

            // Do not run the verification loop if IAPs are not supported
            guard let iap else {
                // Just ensure that the profile does not require any paid feature
                guard originalProfile.native.features.isEmpty else {
                    throw PartoutError(.App.ineligibleProfile)
                }
                return
            }

            // Prepare for periodic receipt verification
            let params = iap.verificationParameters
            appLogger.log(.iap, .info, "Will start profile verification in \(params.delay) seconds")

            // Do not wait for this to start the tunnel. If on-demand is
            // enabled, networking will stall and StoreKit network calls may
            // produce a deadlock (see #1070)
            verifierSubscription = Task { [weak self] in
                guard let self else { return }
                try await Task.sleep(for: .seconds(params.delay))
                guard !Task.isCancelled else { return }
                await verifyEligibility(
                    of: originalProfile.native,
                    iapManager: iap.manager,
                    environment: environment,
                    params: params,
                    isRelaxed: iap.usesRelaxedVerification
                )
            }
        } catch {
            appLogger.log(.core, .fault, "Unable to start tunnel: \(error)")
            Self.flushLogs()
            throw error
        }
    }

    public func stop() async {
        verifierSubscription?.cancel()
        await daemon.stop()
        Self.flushLogs()
        untrackContext()
    }

    public func sendMessage(_ messageData: Data) async -> Data? {
        appLogger.log(.core, .debug, "Handle PTP message")
        do {
            let input = try JSONDecoder().decode(Message.Input.self, from: messageData)
            let output = try await daemon.sendMessage(input)
            let encodedOutput = try JSONEncoder().encode(output)
            switch input {
            case .environment:
                break
            default:
                appLogger.log(.core, .info, "Message handled and response encoded (\(encodedOutput.asSensitiveBytes(.init(originalProfile.id))))")
            }
            return encodedOutput
        } catch {
            appLogger.log(.core, .error, "Unable to decode message: \(messageData)")
            return nil
        }
    }

    public func cancel(_ error: Error?) {
        Self.flushLogs()
    }

    public nonisolated func log(_ category: ABI.AppLogCategory, _ level: ABI.AppLogLevel, _ message: String) {
        appLogger.log(category, level, message)
    }
}

// MARK: - Tracking and Logging

private extension TunnelABI {
    static nonisolated func flushLogs() {
        PartoutLogger.default.flushLog()
    }

    static var activeTunnels: Set<Profile.ID> = [] {
        didSet {
            pp_log_g(.App.core, .info, "Active tunnels: \(activeTunnels)")
        }
    }

    func trackContext() throws {
        // TODO: #218, keep this until supported
        guard Self.activeTunnels.isEmpty else {
            throw PartoutError(.App.multipleTunnels)
        }
        appLogger.log(.core, .info, "Track context: \(daemon.profile.id)")
        Self.activeTunnels.insert(daemon.profile.id)
    }

    func untrackContext() {
        appLogger.log(.core, .info, "Untrack context: \(daemon.profile.id)")
        Self.activeTunnels.remove(daemon.profile.id)
    }
}

// MARK: - Receipt verification

private extension TunnelABI {
    func verifyEligibility(
        of profile: Profile,
        iapManager: IAPManager,
        environment: TunnelEnvironment,
        params: ABI.Constants.Tunnel.Verification.Parameters,
        isRelaxed: Bool
    ) async {
        var attempts = params.attempts
        while true {
            guard !Task.isCancelled else {
                return
            }
            do {
                appLogger.log(.iap, .info, "Verify profile, requires: \(profile.features)")
                await iapManager.reloadReceipt()
                try iapManager.verify(profile)
            } catch {
                if isRelaxed {
                    // Mitigate the StoreKit inability to report errors, sometimes it
                    // would just return empty products, e.g. on network failure. In those
                    // cases, retry a few times before failing
                    if attempts > 0 {
                        attempts -= 1
                        appLogger.log(.iap, .error, "Verification failed for profile \(profile.id), next attempt in \(params.retryInterval) seconds... (remaining: \(attempts), products: \(iapManager.purchasedProducts))")
                        try? await Task.sleep(interval: params.retryInterval)
                        continue
                    }
                }

                let error = PartoutError(.App.ineligibleProfile)
                environment.setEnvironmentValue(error.code, forKey: TunnelEnvironmentKeys.lastErrorCode)
                appLogger.log(.iap, .fault, "Verification failed for profile \(profile.id), shutting down: \(error)")

                // Hold on failure to prevent on-demand reconnection
                environment.setEnvironmentValue(true, forKey: TunnelEnvironmentKeys.holdFlag)
                await daemon.hold()
                return
            }

            appLogger.log(.iap, .info, "Will verify profile again in \(params.interval) seconds...")
            try? await Task.sleep(interval: params.interval)

            // On successful verification, reset attempts for the next verification
            attempts = params.attempts
        }
    }
}

private extension TunnelEnvironmentKeys {
    static let holdFlag = TunnelEnvironmentKey<Bool>("Tunnel.onHold")
}
