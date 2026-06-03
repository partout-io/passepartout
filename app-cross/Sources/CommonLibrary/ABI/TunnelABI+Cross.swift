// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#if PSP_ABI
import CommonLibrary_C
import Partout

extension TunnelABI {
    // TODO: #218, cachesURL must be per-profile
    public static func forCrossPlatform(
        bindings: psp_tunnel_bindings,
        appBundleData: Data,
        appConstantsData: Data,
        preferencesData: Data?,
        profileInput: ABI.ProfileImporterInput,
        cachesURL: URL
    ) throws -> TunnelABI {
        let bundle = try ABI.decode(ABI.AppBundle.self, from: appBundleData)
        let constants = try ABI.decode(ABI.AppConstants.self, from: appConstantsData)
        let appConfiguration = ABI.AppConfiguration(bundle: bundle, constants: constants)
        let preferences = AppPreferencesStore.fromData(preferencesData)

        // Initialize objects from global configuration
        // TODO: #218, this directory must be per-profile
        let registry = appConfiguration.newRegistryForTunnel(
            preferences: preferences,
            cachesURL: cachesURL
        )
        let profile = try registry.importedProfile(from: profileInput, passphrase: nil)
        let environment = SharedTunnelEnvironment(profileId: profile.id)
        let logFormatter = appConfiguration.newLogFormatter()

        // Logging context
        let ctx = pspLogRegister(
            for: .tunnelProfile(profile.id),
            with: appConfiguration,
            preferences: preferences,
            localURL: nil,
            localMapper: logFormatter?.localMapper
        )
        pspLog(.abi, .debug, "Tunnel preferences: \(preferences.serialized())")

        // Create platform-specific objects
        let controller = try NativeTunnelController(
            ctx,
            ref: bindings.controller,
            environment: environment
        )
        let betterPathFactory: BetterPathStreamFactory
#if !PSP_CROSS
        betterPathFactory = NEBetterPathStreamFactory(ctx)
#else
        betterPathFactory = controller.betterPathFactory
#endif
        let factory = BSDSocketFactory(
            ctx,
            betterPathFactory: betterPathFactory,
            configurator: controller.socketConfigurator()
        )

        let connectionOptions = ConnectionParameters.Options()
        let connectionParameters = ConnectionParameters(
            profile: profile,
            controller: controller,
            factory: factory,
            reachability: controller,
            environment: environment,
            options: connectionOptions
        )
        let daemonParameters = SimpleConnectionDaemon.Parameters(
            connectionFactory: registry,
            connectionParameters: connectionParameters,
            messageHandler: DefaultMessageHandler(ctx, environment: environment),
            startsImmediately: false,
            cancelsUnrecoverable: true,
            minDataCountDelta: constants.tunnel.minDataCountDelta.map(\.magnitude)
        )
        let daemon = try SimpleConnectionDaemon(params: daemonParameters)

        // No in-app purchases for now
        return TunnelABI(
            daemon: daemon,
            environment: environment,
            iap: nil,
            originalProfile: profile,
            bindings: bindings
        )
    }
}
#endif
