// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonLibrary

@MainActor
public protocol AppContextProtocol: AnyObject {
    var appConfiguration: ABI.AppConfiguration { get }

    // Manager-backed observables
    var appEncoderObservable: AppEncoderObservable { get }
    var configObservable: ConfigObservable { get }
    var iapObservable: IAPObservable { get }
    var profileObservable: ProfileObservable { get }
    var registryObservable: RegistryObservable { get }
    var versionObservable: VersionObservable { get }
    var webReceiverObservable: WebReceiverObservable { get }

    // Legacy managers not migrated to observables
    @available(*, deprecated, message: "#1679")
    var apiManager: APIManager { get }
    @available(*, deprecated, message: "#1679")
    var preferencesManager: PreferencesManager { get }

    // Tunnel concerns
    var tunnelObservable: TunnelObservable { get }

    // View concerns
    var appFormatter: AppFormatter { get }
    var onboardingObservable: OnboardingObservable { get }
    var userPreferences: UserPreferencesObservable { get }

    func onApplicationActive()
}

extension AppContext: AppContextProtocol {
}

extension LegacyAppContext: AppContextProtocol {
}
