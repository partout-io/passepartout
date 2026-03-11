// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#if PSP_ABI
import Partout

extension TunnelABI {
    // TODO: #218, cachesURL must be per-profile
    public static func forCrossPlatform(
        appBundleData: Data,
        appConstantsData: Data,
        preferencesData: Data?,
        profileInput: ABI.ProfileImporterInput,
        cachesURL: URL,
        jniWrapper: UnsafeMutableRawPointer?
    ) throws -> TunnelABI {
        let decoder = JSONDecoder()

        // Parse preferences
        let preferences = ABI.AppPreferenceValues(
            with: decoder,
            data: preferencesData,
            newDeviceId: true
        )

        // Decode app configuration
        let bundle = try decoder.decode(ABI.AppBundle.self, from: appBundleData)
        let constants = try decoder.decode(ABI.AppConstants.self, from: appConstantsData)
        let appConfiguration = ABI.AppConfiguration(bundle: bundle, constants: constants)

        // Initialize objects from global configuration
        // TODO: #218, this directory must be per-profile
        let registry = appConfiguration.newTunnelRegistry(
            preferences: preferences,
            cachesURL: cachesURL
        )
        let profile = try registry.importedProfile(from: profileInput, passphrase: nil)
        // FIXME: #1656, C ABI, move these to AppConfiguration+Dependencies (PSP_CROSS)
        // FIXME: #1656, C ABI, tunnel environment
        let environment = SharedTunnelEnvironment(profileId: profile.id)
        // FIXME: #1656, C ABI, log formatter
        let logFormatter = DummyLogFormatter()
//        let environment = appConfiguration.newTunnelEnvironment(profileId: profile.id)
//        let logFormatter = appConfiguration.newLogFormatter()

        // Logging context
        let ctx = pspLogRegister(
            for: .tunnelProfile(profile.id),
            with: appConfiguration,
            preferences: preferences,
            mapper: {
                logFormatter.formattedLog(timestamp: $0.timestamp, message: $0.message)
            }
        )

        // Create platform-specific objects
        // FIXME: #1656, C ABI, move these to AppConfiguration+Dependencies (PSP_CROSS)
        let controller = try VirtualTunnelController(ctx, impl: jniWrapper)
        // FIXME: #1656, C ABI, better path block
        let factory = POSIXInterfaceFactory(ctx, betterPathBlock: { PassthroughStream() })
        // FIXME: #1656, C ABI, reachability observer
        let reachability = DummyReachabilityObserver()

        let connectionOptions = ConnectionParameters.Options()
        let connectionParameters = ConnectionParameters(
            profile: profile,
            controller: controller,
            factory: factory,
            reachability: reachability,
            environment: environment,
            options: connectionOptions
        )
        let daemonParameters = SimpleConnectionDaemon.Parameters(
            registry: registry,
            connectionParameters: connectionParameters,
            messageHandler: DefaultMessageHandler(ctx, environment: environment)
        )
        let daemon = try SimpleConnectionDaemon(params: daemonParameters)

        // No in-app purchases for now
        return TunnelABI(
            daemon: daemon,
            environment: environment,
            iap: nil,
            logFormatter: logFormatter,
            originalProfile: profile
        )
    }
}
#endif
