// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#if PSP_ABI
import CommonLibrary_C
import Partout

extension AppABI {
    public static func forCrossPlatform(
        bindings: psp_app_bindings,
        appBundleData: Data,
        appConstantsData: Data,
        preferencesData: Data?,
        profilesDir: String,
        cachesURL: URL
    ) throws -> AppABI {
        let bundle = try ABI.decode(ABI.AppBundle.self, from: appBundleData)
        let constants = try ABI.decode(ABI.AppConstants.self, from: appConstantsData)
        let appConfiguration = ABI.AppConfiguration(bundle: bundle, constants: constants)

        // Parse preferences
        let preferences = AppPreferencesStore(p: ABI.AppPreferences.forInitialization(
            data: preferencesData,
            newDeviceIdLength: constants.deviceIdLength
        ))
        assert(preferences.p.deviceId != nil, "Missing Device ID")
        let deviceId = preferences.p.deviceId ?? "BogusDeviceID"

        // Logging context
        let logFormatter = appConfiguration.newLogFormatter()
        _ = pspLogRegister(
            for: .app,
            with: appConfiguration,
            preferences: preferences,
            localMapper: logFormatter?.localMapper
        )

        // Initialize objects from global configuration
        nonisolated(unsafe) let unsafeBindings = bindings
        let configManager = appConfiguration.newConfigManager(
            withTestBundle: false,
            isBeta: {
                false
            },
            fetcher: {
                try await appConfiguration.newRequest(
                    for: $0,
                    cached: false,
                    bindings: unsafeBindings
                )
            }
        )
        let registry = appConfiguration.newRegistryForApp(
            deviceId: deviceId,
            preferences: preferences,
            configManager: configManager,
            cachesURL: cachesURL
        )

        let appEncoder = AppEncoder(coder: registry)
        let profileRepository = try appConfiguration.newFileProfileRepository(path: profilesDir)
        let profileManager = ProfileManager(repository: profileRepository)

        // Dummy
        let iapManager = IAPManager()
        let versionChecker = VersionChecker()
        let webReceiverManager = WebReceiverManager()

        let abi = AppABI(
            apiManager: nil,
            appConfiguration: appConfiguration,
            appEncoder: appEncoder,
            configManager: configManager,
            extensionInstaller: nil,
            iapManager: iapManager,
            logFormatter: logFormatter,
            preferences: preferences,
            preferencesManager: nil,
            profileManager: profileManager,
            registry: registry,
            versionChecker: versionChecker,
            webReceiverManager: webReceiverManager,
            bindings: bindings
        )

        // Register for events
        let eventContext = bindings.event_ctx
        let eventCallback = bindings.event_cb
        let eventHandler = ABI.EventHandler(
            context: eventContext,
            callback: { ctx, event in
                guard let eventCallback else { return }
                do {
                    // Make the event encodable with metadata for decoding
                    let eventWrapper = ABI.EventWrapper(event)
                    let json = try ABI.encodeJSON(eventWrapper)
                    json.withCString {
                        eventCallback(ctx, $0)
                    }
                } catch {
                    assertionFailure("Unable to encode event: \(event), \(error)")
                }
            }
        )
        abi.registerEvents(eventHandler)

        return abi
    }
}
#endif
