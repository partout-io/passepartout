// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import AppAccessibility
import CommonLibrary

@MainActor
public final class AppContext {
    private let abi: AppABI
    public let appConfiguration: ABI.AppConfiguration

    // Observables (yet unused in Main app and active TV app)

    // ABI concerns (reusable cross-platform)
    public let appEncoderObservable: AppEncoderObservable
    public let configObservable: ConfigObservable
    public let iapObservable: IAPObservable
    public let profileObservable: ProfileObservable
    public let registryObservable: RegistryObservable
    public let tunnelObservable: TunnelObservable
    public let versionObservable: VersionObservable
    public let webReceiverObservable: WebReceiverObservable

    // ABI concerns (not migrated to observables, probably won't be)
    @available(*, deprecated, message: "#1679")
    public var apiManager: APIManager { abi.apiManager }
    @available(*, deprecated, message: "#1679")
    public var preferencesManager: PreferencesManager { abi.preferencesManager }

    // View concerns (app-specific)
    public let appFormatter: AppFormatter
    public let onboardingObservable: OnboardingObservable
    public let userPreferences: UserPreferencesObservable

    public init(abi: AppABI, appConfiguration: ABI.AppConfiguration, kvStore: KeyValueStore) {
        self.abi = abi
        self.appConfiguration = appConfiguration

        // ABI
        appEncoderObservable = AppEncoderObservable(abi: abi.encoder)
        configObservable = ConfigObservable()
        iapObservable = IAPObservable(abi: abi.iap)
        profileObservable = ProfileObservable(abi: abi.profile)
        registryObservable = RegistryObservable(abi: abi.registry)
        tunnelObservable = TunnelObservable(abi: abi.tunnel, formatter: abi)
        versionObservable = VersionObservable(abi: abi.version)
        webReceiverObservable = WebReceiverObservable(abi: abi.webReceiver)

        // View
        appFormatter = AppFormatter(constants: appConfiguration.constants)
        userPreferences = UserPreferencesObservable(kvStore: kvStore)
        onboardingObservable = OnboardingObservable(userPreferences: userPreferences)

        // Register for ABI events
        let opaqueEnvironment = Unmanaged.passRetained(self).toOpaque()
        let ctx = ABI.EventContext(pointer: opaqueEnvironment)
        abi.registerEvents(context: ctx, callback: Self.abiCallback)
    }
}

extension AppContext {
    public func onApplicationActive() {
        abi.onApplicationActive()
    }
}

private extension AppContext {
    static nonisolated func abiCallback(
        ctx: ABI.EventContext?,
        event mainEvent: ABI.Event
    ) {
        guard let opaqueEnvironment = ctx?.pointer else {
            fatalError("Missing AppContext from ctx. Bad arguments to abi.registerEvents?")
        }
        let env = Unmanaged<AppContext>.fromOpaque(opaqueEnvironment).takeUnretainedValue()
        Task { @MainActor in
            switch mainEvent {
            case .config(let event):
                env.configObservable.onUpdate(event)
            case .iap(let event):
                env.iapObservable.onUpdate(event)
            case .profile(let event):
                env.profileObservable.onUpdate(event)
            case .tunnel(let event):
                env.tunnelObservable.onUpdate(event)
            case .version(let event):
                env.versionObservable.onUpdate(event)
            case .webReceiver(let event):
                env.webReceiverObservable.onUpdate(event)
            }
        }
    }
}
