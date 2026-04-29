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
        cachesURL: URL,
        onStatus: SimpleConnectionDaemon.StatusCallback?
    ) throws -> TunnelABI {
        let decoder = JSONDecoder()

        // Decode app configuration
        let bundle = try decoder.decode(ABI.AppBundle.self, from: appBundleData)
        let constants = try decoder.decode(ABI.AppConstants.self, from: appConstantsData)
        let appConfiguration = ABI.AppConfiguration(bundle: bundle, constants: constants)

        // Parse preferences
        var preferences = ABI.AppPreferenceValues(
            with: decoder,
            data: preferencesData,
            newDeviceId: true,
            deviceIdLength: constants.deviceIdLength
        )
        preferences.configFlags = [.wgCrossV2]

        // Initialize objects from global configuration
        // TODO: #218, this directory must be per-profile
        let registry = appConfiguration.newRegistryForTunnel(
            preferences: preferences,
            cachesURL: cachesURL
        )
        let profile = try registry.importedProfile(from: profileInput, passphrase: nil)
        let environment = appConfiguration.newStandaloneTunnelEnvironment(profileId: profile.id)
        let logFormatter = appConfiguration.newLogFormatter()

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
        let controller = try VirtualTunnelController(ctx, impl: bindings.controller)
        let factory = BSDSocketFactory(ctx) {
            // FIXME: #1656, C ABI, better path block
            PassthroughStream()
        }
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
            connectionFactory: registry,
            connectionParameters: connectionParameters,
            messageHandler: DefaultMessageHandler(ctx, environment: environment),
            startsImmediately: false,
            onStatus: onStatus
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
