// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#if canImport(CommonLibraryApple)
import CommonLibrary
import NetworkExtension
import Partout
import PartoutRuntime
import TunnelLibrary

extension TunnelContext {
    public static func forProduction(
        neProvider: NEPacketTunnelProvider,
        appConfiguration: ABI.AppConfiguration,
        preferences: AppPreferencesStore
    ) async throws -> TunnelContext {
        guard let bundleIdentifier = Bundle.main.bundleIdentifier else {
            fatalError("Nil .bundleIdentifier?")
        }
        let keychain = appConfiguration.newKeychain(
            .global,
            bundleIdentifier: bundleIdentifier
        )
        // TODO: #218, cachesURL must be per-profile
        let cachesURL = FileManager.default.temporaryDirectory

        // Pick runtime based on config flag
        let runtime = try {
            if preferences.isFlagEnabled(.zigRuntime) {
                do {
                    return try newZigRuntime(
                        neProvider: neProvider,
                        appConfiguration: appConfiguration,
                        preferences: preferences,
                        keychain: keychain,
                        cachesURL: cachesURL
                    )
                } catch RuntimeError.undecodableProfile,
                        RuntimeError.unsupportedProviders {
                    // Fall back to Swift
                }
            }
            return try newSwiftRuntime(
                neProvider: neProvider,
                appConfiguration: appConfiguration,
                preferences: preferences,
                keychain: keychain,
                cachesURL: cachesURL
            )
        }()

        // Create IAPManager for receipt verification
        let iapManager = appConfiguration.newIAPManager(
            inAppHelper: appConfiguration.newInAppHelper(),
            receiptReader: SharedReceiptReader(
                reader: appConfiguration.newInAppReceiptReader {
                    // TODO: #1786, StoreKit receipt caching
                    .uncached
                },
            ),
            betaChecker: appConfiguration.newBetaChecker()
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

    enum RuntimeError: Error {
        case undecodableProfile
        case unsupportedProviders
    }

    static func newZigRuntime(
        neProvider: NEPacketTunnelProvider,
        appConfiguration: ABI.AppConfiguration,
        preferences: AppPreferencesStore,
        keychain: Keychain,
        cachesURL: URL
    ) throws -> ProductionRuntime {
        pspLog(.core, .info, "Using Zig runtime (\(PartoutProviderRuntime.version))")

        let appGroup = appConfiguration.bundle.bundleString(for: .groupId)
        guard let defaults = UserDefaults(suiteName: appGroup) else {
            fatalError("No access to App Group: \(appGroup)")
        }
        // Profile decoding requires no registry. Parse as TaggedProfile
        // and rethrow on failure.
        let coder = TaggedProfileCoder()
        let decoder = appConfiguration.newNEProtocolCoder(
            .global,
            coder: coder,
            keychain: keychain
        )
        let profile: Profile
        do {
            profile = try Profile(withNEProvider: neProvider, decoder: decoder)
        } catch {
            pspLog(.profiles, .error, "Unable to decode profile in Zig (legacy?), falling back to Swift runtime: \(error)")
            throw RuntimeError.undecodableProfile
        }

        let backend = try PartoutProviderRuntime(
            provider: neProvider,
            profile: profile,
            options: .init(
                dnsFallbackServers: appConfiguration.constants.tunnel.dnsFallbackServers,
                logsSnapshots: false
            ),
            defaults: defaults,
            logsPrivateData: preferences[\.logsPrivateData],
            cacheDir: cachesURL.path(),
            minDataCountDelta: appConfiguration.constants.tunnel.minDataCountDelta,
            logger: logger
        )

        // Profiles with provider modules require the Swift runtime
        guard profile.activeProviderModule == nil else {
            pspLog(profile.id, .profiles, .error, "Providers are not supported by Zig, falling back to Swift runtime")
            throw RuntimeError.unsupportedProviders
        }

        let environment = appConfiguration.newTunnelEnvironment(profileId: profile.id)
        return ProductionRuntime(
            backend: backend,
            originalProfile: profile,
            environment: environment
        )
    }

    static func newSwiftRuntime(
        neProvider: NEPacketTunnelProvider,
        appConfiguration: ABI.AppConfiguration,
        preferences: AppPreferencesStore,
        keychain: Keychain,
        cachesURL: URL
    ) throws -> ProductionRuntime {
        pspLog(.core, .info, "Using Swift runtime")

        // Create global registry
        let registry = appConfiguration.newRegistryForTunnel(
            preferences: preferences,
            cachesURL: cachesURL
        )

        // Decode profile from NE provider
        let originalProfile: Profile
        let processedProfile: Profile
        do {
            let decoder = appConfiguration.newNEProtocolCoder(
                .global,
                coder: registry,
                keychain: keychain
            )
            originalProfile = try Profile(withNEProvider: neProvider, decoder: decoder)
            let resolvedProfile = try registry.resolvedProfile(originalProfile)
            let processor = appConfiguration.newTunnelProcessor()
            processedProfile = try processor.willProcess(resolvedProfile)
        } catch {
            pspLog(.profiles, .fault, "Unable to decode or process profile: \(error)")
            throw error
        }
        let environment = appConfiguration.newTunnelEnvironment(profileId: processedProfile.id)

        // Update the logger now that we have a context
        assert(processedProfile.id == originalProfile.id)
        let logFormatter = appConfiguration.newLogFormatter()
        let ctx = pspLogRegister(
            for: .tunnelProfile(processedProfile.id),
            with: appConfiguration,
            preferences: preferences,
            localURL: appConfiguration.urlForTunnelLog,
            localMapper: logFormatter.localMapper
        )

        // Decode preferences and config flags
        pspLog(ctx.profileId, .core, .info, "Tunnel profile initialized")
        let configFlags = preferences[\.configFlags]
        pspLog(ctx.profileId, .core, .info, "\tActive config flags: \(configFlags)")
        pspLog(ctx.profileId, .core, .info, "\tIgnored config flags: \(preferences[\.experimental.ignoredConfigFlags])")
        pspLog(ctx.profileId, .core, .info, "\tEnabled config flags: \(preferences[\.experimental.enabledConfigFlags])")

        // Create TunnelController for connnection management
        let neTunnelController = NETunnelController(
            provider: neProvider,
            profile: processedProfile,
            options: {
                var options = TunnelControllerOptions()
                if preferences[\.dnsFallsBack] {
                    options.dnsFallbackServers = appConfiguration.constants.tunnel.dnsFallbackServers
                }
                return options
            }()
        )

        // Create daemon
        let factory: NetworkInterfaceFactory
        if preferences.isFlagEnabled(.ovpnV3) {
            factory = NativeSocketFactory(ctx, betterPathFactory: NEBetterPathStreamFactory(ctx))
        } else {
            let options = NEInterfaceFactory.Options()
            factory = NEInterfaceFactory(ctx, provider: neProvider, options: options)
        }
        let reachability = NEObservablePath(ctx)
        let connectionOptions = ConnectionParameters.Options()
        let connectionParameters = ConnectionParameters(
            profile: processedProfile,
            controller: neTunnelController,
            factory: factory,
            reachability: reachability,
            environment: environment,
            options: connectionOptions
        )
        let messageHandler = DefaultMessageHandler(ctx, environment: environment)
        let params = SimpleConnectionDaemon.Parameters(
            connectionFactory: registry,
            connectionParameters: connectionParameters,
            messageHandler: messageHandler,
            startsImmediately: true,
            cancelsUnrecoverable: false // Prevents on-demand reconnection
        )
        let backend = try SimpleConnectionDaemon(params: params)
        return ProductionRuntime(
            backend: backend,
            originalProfile: originalProfile,
            environment: environment
        )
    }
}

private struct TaggedProfileCoder: ProfileCoder {
    func profile(fromString string: String) throws -> Profile {
        try ABI.decodeJSON(TaggedProfile.self, from: string).asProfile()
    }

    func string(fromProfile profile: Profile) throws -> String {
        try ABI.encodeJSON(profile.asTaggedProfile)
    }
}

private nonisolated func logger(
    _ level: Int32,
    _ message: UnsafePointer<CChar>?
) {
    guard let level = ABI.AppLogLevel(partoutCLevel: level),
          let message else { return }
    pspLog(.abi, level, String(cString: message))
}
#endif
