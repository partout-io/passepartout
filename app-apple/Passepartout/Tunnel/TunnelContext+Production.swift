// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#if canImport(CommonLibraryApple)
import CommonLibrary
import NetworkExtension
import Partout
import PartoutRuntime
import TunnelLibrary

extension PartoutProviderRuntime: @retroactive TunnelBackendProtocol {
    public func start() async throws {
        try await startTunnel()
    }

    public func stop() async {
        await stopTunnel()
    }

    public func hold() async {
        await holdTunnel()
    }

    public func sendMessage(_ messageData: Data) async throws -> Data? {
        await handleAppMessage(messageData)
    }
}

extension TunnelContext {
    enum RuntimeError: Error {
        case unsupportedProviders
    }

    static func forProduction(
        neProvider: NEPacketTunnelProvider,
        appConfiguration: ABI.AppConfiguration,
        preferences: AppPreferencesStore
    ) async throws -> TunnelContext {
        guard let bundleIdentifier = Bundle.main.bundleIdentifier else {
            fatalError("Nil .bundleIdentifier?")
        }
        // TODO: #218, cachesURL must be per-profile
        let cachesURL = FileManager.default.temporaryDirectory

        // Pick runtime based on config flag
        let runtime = try newZigRuntime(
            neProvider: neProvider,
            bundleIdentifier: bundleIdentifier,
            appConfiguration: appConfiguration,
            preferences: preferences,
            cachesURL: cachesURL
        )

        // Create IAPManager for receipt verification
        let iapManager = appConfiguration.makeIAPManager(
            inAppHelper: appConfiguration.makeInAppHelper(),
            receiptReader: SharedReceiptReader(
                reader: appConfiguration.makeInAppReceiptReader {
                    // TODO: #1786, StoreKit receipt caching
                    .uncached
                },
            ),
            betaChecker: appConfiguration.makeBetaChecker()
        )
        await iapManager.fetchLevelIfNeeded()
        let skipsPurchases = !appConfiguration.bundle.distributionTarget.supportsIAP || preferences[\.skipsPurchases]
        let verificationParameters = appConfiguration.constants.tunnel.verificationParameters(isBeta: iapManager.isBeta)
        let iap = TunnelContext.IAP(
            manager: iapManager,
            skipsPurchases: skipsPurchases,
            verificationParameters: verificationParameters
        )

        return TunnelContext(
            backend: runtime.backend,
            originalProfile: runtime.originalProfile,
            environment: runtime.environment,
            iap: iap
        )
    }
}

private extension TunnelContext {
    struct ProductionRuntime {
        let backend: TunnelBackendProtocol
        let originalProfile: Profile
        let environment: TunnelEnvironment
    }

    static func newZigRuntime(
        neProvider: NEPacketTunnelProvider,
        bundleIdentifier: String,
        appConfiguration: ABI.AppConfiguration,
        preferences: AppPreferencesStore,
        cachesURL: URL
    ) throws -> ProductionRuntime {
        pspLog(.core, .info, "Using Zig runtime")

        // This depends on distribution target
        let defaults = appConfiguration.makeTunnelDefaults()

        // This is only to get the profile ID.
        let plainCodingPair = appConfiguration.makeKeychainAndNECoder(
            .global,
            bundleIdentifier: bundleIdentifier,
            coder: TaggedProfileCoder(resolved: false)
        )

        // Profile decoding requires no registry. Parse as TaggedProfile
        // and rethrow on failure.
        let resolvingCodingPair = appConfiguration.makeKeychainAndNECoder(
            .global,
            bundleIdentifier: bundleIdentifier,
            coder: TaggedProfileCoder(resolved: true)
        )

        // Validate decoded profile
        let profile: Profile
        do {
            let originalProfile = try Profile(
                withNEProvider: neProvider,
                decoder: plainCodingPair.neCoder
            )
            let resolvedProfile: Profile
            do {
                resolvedProfile = try Profile(
                    withNEProvider: neProvider,
                    decoder: resolvingCodingPair.neCoder
                )
            } catch let error as RuntimeError {
                let env = UserDefaultsEnvironment(
                    profileId: originalProfile.id,
                    defaults: defaults
                )
                // XXX: Required to show error in UI
                env.setEnvironmentValue(
                    ConnectionStatus.disconnected,
                    forKey: TunnelEnvironmentKeys.connectionStatus
                )
                env.setEnvironmentValue(
                    ABI.AppErrorCode.providersRemoved.toLastErrorCode,
                    forKey: TunnelEnvironmentKeys.lastErrorCode
                )
                throw error
            }
            assert(originalProfile == resolvedProfile)
            let processor = appConfiguration.makeTunnelProcessor()
            profile = try processor.willProcess(resolvedProfile)
        } catch {
            pspLog(.profiles, .fault, "Unable to decode profile: \(error)")
            throw error
        }

        // Replace the bootstrap logger with the profile-aware logger configured
        // from the preferences loaded by the tunnel provider.
        let logFormatter = appConfiguration.makeLogFormatter()
        _ = pspLogRegister(
            for: .tunnelProfile(profile.id),
            with: appConfiguration,
            preferences: preferences,
            localURL: appConfiguration.urlForTunnelLog,
            localMapper: logFormatter.localMapper
        )

        // Clean up residual Swift/Zig mismatches
        var builder = profile.builder()
        builder.modules = try builder.modules.map {
            if let wg = $0 as? WireGuardModule {
                return try wg.builder().build()
            }
            return $0
        }
        let normalizedProfile = try builder.build()

        let backend = try PartoutProviderRuntime(
            provider: neProvider,
            profile: normalizedProfile,
            options: .init(
                dnsFallbackServers: appConfiguration.constants.tunnel.dnsFallbackServers,
                logsSnapshots: false
            ),
            defaults: defaults,
            logsPrivateData: preferences[\.logsPrivateData],
            cacheDir: cachesURL.path(),
            minDataCountDelta: appConfiguration.constants.tunnel.minDataCountDelta,
            cryptoBackend: CryptoBackend(rawValue: preferences[\.cryptoBackend]),
            logger: logger
        )

        return ProductionRuntime(
            backend: backend,
            originalProfile: normalizedProfile,
            environment: backend.environment
        )
    }
}

private struct TaggedProfileCoder: ProfileCoder {
    let resolved: Bool

    func profile(fromString string: String) throws -> Profile {
        let profile = try ABI.decodeJSON(TaggedProfile.self, from: string)
        guard resolved else {  return try profile.asProfile() }

        // Profiles with custom (provider) modules require the Swift runtime
        return try profile.asProfile { _ in
            pspLog(profile.id, .profiles, .fault,
                   "Custom modules (providers) are not supported")
            throw TunnelContext.RuntimeError.unsupportedProviders
        }
    }

    func string(fromProfile profile: Profile) throws -> String {
        try ABI.encodeJSON(profile.asTaggedProfile)
    }
}

private nonisolated func logger(
    _ ctx: UnsafeMutableRawPointer?,
    _ level: Int32,
    _ message: UnsafePointer<CChar>?
) {
    guard let level = ABI.AppLogLevel(partoutCLevel: level),
          let message else { return }
    pspLog(.abi, level, String(cString: message))
}
#endif
