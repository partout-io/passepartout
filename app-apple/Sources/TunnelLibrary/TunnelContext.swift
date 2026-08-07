// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonLibrary
import Partout

public final class TunnelContext: TunnelContextProtocol {
    public struct IAP: Sendable {
        let manager: IAPManager
        let skipsPurchases: Bool
        let verificationParameters: ABI.AppConstants.TunnelVerificationParameters

        public init(
            manager: IAPManager,
            skipsPurchases: Bool,
            verificationParameters: ABI.AppConstants.TunnelVerificationParameters
        ) {
            self.manager = manager
            self.skipsPurchases = skipsPurchases
            self.verificationParameters = verificationParameters
        }
    }

    private var backend: TunnelBackendProtocol?
    private let originalProfile: Profile
    private let environment: TunnelEnvironment
    private let iap: IAP?

    private var verifierSubscription: Task<Void, Error>?

    public init(
        backend: TunnelBackendProtocol,
        originalProfile: Profile,
        environment: TunnelEnvironment,
        iap: IAP?
    ) {
        self.backend = backend
        self.originalProfile = originalProfile
        self.environment = environment
        self.iap = iap

        // Disable if skips purchases
        if let iap {
            iap.manager.isEnabled = !iap.skipsPurchases
        }
    }

    deinit {
        pspLog(.abi, .debug, "Deinit TunnelContext")
    }

    public func start(isInteractive: Bool) async throws {
        guard let backend else { return }
        try trackContext()

        do {
            // Check hold flag and hang the tunnel if set
            if environment.environmentValue(forKey: TunnelEnvironmentKeys.holdFlag) == true {
                pspLog(.abi, .info, "Tunnel is on hold")
                guard isInteractive else {
                    pspLog(.abi, .error, "Tunnel was started non-interactively, hang here")
                    await backend.hold()
                    return
                }
                pspLog(.abi, .info, "Tunnel was started interactively, clear hold flag")
                environment.removeEnvironmentValue(forKey: TunnelEnvironmentKeys.holdFlag)
            }

            // Start the tunnel
            try await backend.start()

            // Do not run the verification loop if IAPs are not supported
            guard let iap else {
                // Just ensure that the profile does not require any paid feature
                guard originalProfile.features.isEmpty else {
                    throw ABI.AppError.ineligibleProfile(originalProfile.features)
                }
                return
            }

            // Prepare for periodic receipt verification
            let params = iap.verificationParameters
            pspLog(.iap, .info, "Will start profile verification in \(params.delay) seconds")

            // Do not wait for this to start the tunnel. If on-demand is
            // enabled, networking will stall and StoreKit network calls may
            // produce a deadlock (see #1070)
            verifierSubscription = Task { [weak self] in
                guard let self else { return }
                try await Task.sleep(for: .seconds(params.delay))
                guard !Task.isCancelled else { return }
                await verifyEligibility(
                    of: originalProfile,
                    iapManager: iap.manager,
                    environment: environment,
                    params: params
                )
            }
        } catch {
            pspLog(.abi, .fault, "Unable to start tunnel: \(error)")
            flushLogs()
            throw error
        }
    }

    public func stop() async {
        guard let backend else { return }
        verifierSubscription?.cancel()
        verifierSubscription = nil
        await backend.stop()
        flushLogs()
        untrackContext()
        self.backend = nil
    }

    public func sendMessage(_ messageData: Data) async -> Data? {
        guard let backend else { return nil }
        pspLog(.abi, .debug, "Handle tunnel message")
        do {
            let input = try ABI.decode(Message.Input.self, from: messageData)
            let encodedOutput = try await backend.sendMessage(messageData)
            switch input {
            case .environment:
                break
            default:
                let outputDescription = encodedOutput?.asSensitiveBytes(.init(originalProfile.id)) ?? "nil"
                pspLog(.abi, .info, "Message handled and response encoded (\(outputDescription))")
            }
            return encodedOutput
        } catch {
            pspLog(.abi, .error, "Unable to handle message: \(error)")
            return nil
        }
    }

    public nonisolated func cancel(_ error: Error?) {
        flushLogs()
    }

    public nonisolated func log(_ category: ABI.AppLogCategory, _ level: ABI.AppLogLevel, _ message: String) {
        pspLog(category, level, message)
    }

    public nonisolated func flushLogs() {
        pspLogFlush()
    }
}

// MARK: - Tracking and Logging

private extension TunnelContext {
    static var activeTunnels: Set<Profile.ID> = [] {
        didSet {
            pspLog(.abi, .info, "Active tunnels: \(activeTunnels)")
        }
    }

    func trackContext() throws {
        guard backend != nil else { return }
        // TODO: #218, keep this until supported
        guard Self.activeTunnels.isEmpty else {
            throw ABI.AppError.multipleTunnels
        }
        pspLog(.abi, .info, "Track context: \(originalProfile.id)")
        Self.activeTunnels.insert(originalProfile.id)
    }

    func untrackContext() {
        guard backend != nil else { return }
        pspLog(.abi, .info, "Untrack context: \(originalProfile.id)")
        Self.activeTunnels.remove(originalProfile.id)
    }
}

// MARK: - Receipt verification

private extension TunnelContext {
    func verifyEligibility(
        of profile: Profile,
        iapManager: IAPManager,
        environment: TunnelEnvironment,
        params: ABI.AppConstants.TunnelVerificationParameters
    ) async {
        var attempts = params.attempts
        while true {
            guard let backend else { return }
            guard !Task.isCancelled else { return }

            // Perform periodic verification
            do {
                pspLog(.iap, .info, "Verify profile, requires: \(profile.features)")
                await iapManager.reloadReceipt()
                try iapManager.verify(profile)
            } catch {
                // Mitigate the StoreKit inability to report errors, sometimes it
                // would just return empty products, e.g. on network failure. In those
                // cases, retry a few times before failing.
                if attempts > 0 {
                    attempts -= 1
                    let products = iapManager.purchasedProducts
                    pspLog(.iap, .error, "Verification failed for profile \(profile.id), next attempt in \(params.retryInterval) seconds... (remaining: \(attempts), products: \(products))")
                    try? await Task.sleep(interval: params.retryInterval)
                    continue
                }

                let errorCode: ABI.AppErrorCode = .ineligibleProfile
                environment.setEnvironmentValue(errorCode.toLastErrorCode, forKey: TunnelEnvironmentKeys.lastErrorCode)
                pspLog(.iap, .fault, "Verification failed for profile \(profile.id), shutting down: \(error)")

                // Hold on failure to prevent on-demand reconnection
                environment.setEnvironmentValue(true, forKey: TunnelEnvironmentKeys.holdFlag)
                await backend.hold()
                return
            }

            // Retry in a while
            pspLog(.iap, .info, "Will verify profile again in \(params.interval) seconds...")
            try? await Task.sleep(interval: params.interval)

            // On successful verification, reset attempts for the next verification
            attempts = params.attempts
        }
    }
}

private extension TunnelEnvironmentKeys {
    static let holdFlag = TunnelEnvironmentKey<Bool>("Tunnel.onHold")
}
