// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import AppAccessibility
import CommonLibrary

@MainActor
public final class AppContext {
    private let abi: AppABI
    public let appConfiguration: ABI.AppConfiguration

    // ABI concerns (reusable cross-platform)
    public let appEncoderObservable: AppEncoderObservable
    public let configObservable: ConfigObservable
    public let iapObservable: IAPObservable
    public let profileObservable: ProfileObservable
    public let registryObservable: RegistryObservable
    public let versionObservable: VersionObservable
    public let webReceiverObservable: WebReceiverObservable

    // ABI concerns (not migrated to observables, probably won't be)
    @available(*, deprecated, message: "#1679")
    public var apiManager: APIManager { abi.apiManager }
    @available(*, deprecated, message: "#1679")
    public var preferencesManager: PreferencesManager { abi.preferencesManager }

    // Tunnel concerns
    public let tunnelObservable: TunnelObservable

    // View concerns (app-specific)
    public let appFormatter: AppFormatter
    public let onboardingObservable: OnboardingObservable
    public let userPreferences: UserPreferencesObservable

    public init(abi: AppABI, appConfiguration: ABI.AppConfiguration, kvStore: KeyValueStore, tunnel: Tunnel, sysexManager: ExtensionInstaller?) {
        self.abi = abi
        self.appConfiguration = appConfiguration

        // ABI
        appEncoderObservable = AppEncoderObservable(abi: abi.encoder)
        configObservable = ConfigObservable()
        iapObservable = IAPObservable(abi: abi.iap)
        profileObservable = ProfileObservable(abi: abi.profile)
        registryObservable = RegistryObservable(abi: abi.registry)
        versionObservable = VersionObservable(abi: abi.version)
        webReceiverObservable = WebReceiverObservable(abi: abi.webReceiver)

        // Tunnel
        tunnelObservable = TunnelObservable(
            tunnel: tunnel,
            kvStore: kvStore,
            extensionInstaller: sysexManager,
            logging: appConfiguration.newTunnelLogging(formatter: abi)
        )

        // View
        appFormatter = AppFormatter(constants: appConfiguration.constants)
        userPreferences = UserPreferencesObservable(kvStore: kvStore)
        onboardingObservable = OnboardingObservable(userPreferences: userPreferences)

        // Register for ABI events
        let opaqueEnvironment = Unmanaged.passRetained(self).toOpaque()
        let handler = ABI.EventHandler(context: opaqueEnvironment, callback: Self.abiCallback)
        abi.registerEvents(handler)

        // Register for tunnel events
        tunnelObservable.observeObjects()
    }
}

extension AppContext {
    public func onApplicationActive() {
        abi.onApplicationActive()
    }
}

private extension AppContext {
    static nonisolated func abiCallback(
        ctx: UnsafeMutableRawPointer?,
        event mainEvent: ABI.Event
    ) {
        guard let opaqueContext = ctx else {
            fatalError("Missing AppContext from ctx. Bad arguments to abi.registerEvents?")
        }
        let appContext = Unmanaged<AppContext>.fromOpaque(opaqueContext).takeUnretainedValue()
        Task { @MainActor in
            switch mainEvent {
            case .config(let event):
                appContext.configObservable.onUpdate(event)
            case .iap(let event):
                appContext.iapObservable.onUpdate(event)
            case .profile(let event):
                appContext.profileObservable.onUpdate(event)
            case .version(let event):
                appContext.versionObservable.onUpdate(event)
            case .webReceiver(let event):
                appContext.webReceiverObservable.onUpdate(event)
            }
        }
    }
}
