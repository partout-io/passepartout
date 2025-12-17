// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import AppAccessibility
import CommonLibrary
import Partout

@MainActor
public final class AppContext {
    private let abi: ABIProtocol

    // Global configuration
    public var appConfiguration: ABI.AppConfiguration {
        abi.appConfiguration
    }

    // Observables (yet unused in Main app and active TV app)
    public let appearanceObservable: AppearanceObservable
    public let appEncoderObservable: AppEncoderObservable
    public let appFormatter: AppFormatter
    public let configObservable: ConfigObservable
    public let iapObservable: IAPObservable
    public let onboardingObservable: OnboardingObservable
    public let profileObservable: ProfileObservable
    public let tunnelObservable: TunnelObservable
    public let userPreferences: UserPreferencesObservable
    public let versionObservable: VersionObservable
    public let viewLogger: ViewLogger
    public let webReceiverObservable: WebReceiverObservable

    public init(
        abi: ABIProtocol,
        onboardingObservable: OnboardingObservable? = nil,
    ) {
        self.abi = abi

        // Environment
        appearanceObservable = AppearanceObservable(kvManager: abi.kvManager)
        appEncoderObservable = AppEncoderObservable(encoder: abi.appEncoder)
        appFormatter = AppFormatter(constants: abi.appConfiguration.constants)
        configObservable = ConfigObservable(configManager: abi.configManager)
        iapObservable = IAPObservable(logger: abi.logger, iapManager: abi.iapManager)
        self.onboardingObservable = onboardingObservable ?? OnboardingObservable()
        profileObservable = ProfileObservable(logger: abi.logger, profileManager: abi.profileManager)
        tunnelObservable = TunnelObservable(logger: abi.logger, extendedTunnel: abi.tunnel)
        userPreferences = UserPreferencesObservable(kvManager: abi.kvManager)
        versionObservable = VersionObservable(versionChecker: abi.versionChecker)
        viewLogger = ViewLogger(strategy: abi.logger)
        webReceiverObservable = WebReceiverObservable(webReceiverManager: abi.webReceiverManager)

        // Register for ABI events
        let opaqueEnvironment = Unmanaged.passRetained(self).toOpaque()
        let ctx = ABIEventContext(pointer: opaqueEnvironment)
        abi.registerEvents(context: ctx, callback: Self.abiCallback)
    }
}

extension AppContext {
    public func assertMissingImplementations() {
        CommonLibrary.assertMissingImplementations(with: abi.registry)
        ModuleType.allCases.forEach { moduleType in
            let builder = moduleType.newModule(with: abi.registry)

            // ModuleViewProviding
            guard builder is any ModuleViewProviding else {
                fatalError("\(moduleType): is not ModuleViewProviding")
            }
        }
    }

    public func onApplicationActive() {
        abi.onApplicationActive()
    }
}

private extension AppContext {
    static nonisolated func abiCallback(ctx: ABIEventContext?, event mainEvent: ABI.Event) {
        guard let opaqueEnvironment = ctx?.pointer else {
            fatalError("Missing AppContext from ctx. Bad arguments to abi.registerEvents?")
        }
        let env = Unmanaged<AppContext>.fromOpaque(opaqueEnvironment).takeUnretainedValue()
        Task { @MainActor in
            switch mainEvent {
            case .iap(let event):
                env.iapObservable.onUpdate(event)
            case .profile(let event):
                env.profileObservable.onUpdate(event)
            case .tunnel(let event):
                env.tunnelObservable.onUpdate(event)
            case .version(let event):
                env.versionObservable.onUpdate(event)
            }
        }
    }
}

// FIXME: #1594, Drop these after using ABI actions in observables
extension AppContext {
    @available(*, deprecated, message: "#1594")
    public var apiManager: APIManager { abi.apiManager }
    @available(*, deprecated, message: "#1594")
    public var configManager: ConfigManager { abi.configManager }
    @available(*, deprecated, message: "#1594")
    public var iapManager: IAPManager { abi.iapManager }
    @available(*, deprecated, message: "#1594")
    public var kvManager: KeyValueManager { abi.kvManager }
    @available(*, deprecated, message: "#1594")
    public var preferencesManager: PreferencesManager { abi.preferencesManager }
    @available(*, deprecated, message: "#1594")
    public var profileManager: ProfileManager { abi.profileManager }
    @available(*, deprecated, message: "#1594")
    public var registry: Registry { abi.registry }
    @available(*, deprecated, message: "#1594")
    public var tunnel: ExtendedTunnel { abi.tunnel }
    @available(*, deprecated, message: "#1594")
    public var versionChecker: VersionChecker { abi.versionChecker }
    @available(*, deprecated, message: "#1594")
    public var webReceiverManager: WebReceiverManager { abi.webReceiverManager }
}
