// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonLibrary
import Observation
import SwiftUI

@MainActor @Observable
public final class UserPreferencesObservable {
    private let abi: AppPreferencesStore
    private let ui: UserDefaults

    public init(abi: AppPreferencesStore, ui: UserDefaults) {
        self.abi = abi
        self.ui = ui

        // Fallbacks
        ui.register(defaults: [
            UIPreference.pinsActiveProfile.key: true
        ])

        dnsFallsBack = abi.p.dnsFallsBack
        experimental = abi.p.experimental
        extensiveLogging = abi.p.extensiveLogging
        keepsInMenu = ui.bool(forUIPreference: .keepsInMenu)
        lastInfrastructureRefresh = ui.object(forUIPreference: .lastInfrastructureRefresh) as? [String: TimeInterval]
        locksInBackground = ui.bool(forUIPreference: .locksInBackground)
        logsPrivateData = abi.p.logsPrivateData
        onboardingStep = ui.string(forUIPreference: .onboardingStep).flatMap {
            OnboardingStep(rawValue: $0)
        }
        onlyShowsFavorites = ui.bool(forUIPreference: .onlyShowsFavorites)
        pinsActiveProfile = ui.bool(forUIPreference: .pinsActiveProfile)
        profilesLayout = ui.string(forUIPreference: .profilesLayout).flatMap {
            ProfilesLayout(rawValue: $0)
        } ?? .list
        relaxedVerification = abi.p.relaxedVerification
        systemAppearance = ui.string(forUIPreference: .systemAppearance).flatMap {
            SystemAppearance(rawValue: $0)
        }
    }

    // MARK: Preferences

    public var dnsFallsBack: Bool {
        didSet {
            abi.p.dnsFallsBack = dnsFallsBack
        }
    }

    public var experimental: ABI.ExperimentalPreferences {
        didSet {
            abi.p.experimental = experimental
        }
    }

    public var extensiveLogging: Bool {
        didSet {
            abi.p.extensiveLogging = extensiveLogging
        }
    }

    public var keepsInMenu: Bool {
        didSet {
            ui.set(keepsInMenu, forUIPreference: .keepsInMenu)
        }
    }

    public var lastInfrastructureRefresh: [String: TimeInterval]? {
        didSet {
            ui.set(lastInfrastructureRefresh, forUIPreference: .lastInfrastructureRefresh)
        }
    }

    public var locksInBackground: Bool {
        didSet {
            ui.set(locksInBackground, forUIPreference: .locksInBackground)
        }
    }

    public var logsPrivateData: Bool {
        didSet {
            abi.p.logsPrivateData = logsPrivateData
        }
    }

    public var onboardingStep: OnboardingStep? {
        didSet {
            ui.set(onboardingStep?.rawValue, forUIPreference: .onboardingStep)
        }
    }

    public var onlyShowsFavorites: Bool {
        didSet {
            ui.set(onlyShowsFavorites, forUIPreference: .onlyShowsFavorites)
        }
    }

    public var pinsActiveProfile: Bool {
        didSet {
            ui.set(pinsActiveProfile, forUIPreference: .pinsActiveProfile)
        }
    }

    public var profilesLayout: ProfilesLayout {
        didSet {
            ui.set(profilesLayout.rawValue, forUIPreference: .profilesLayout)
        }
    }

    public var relaxedVerification: Bool {
        didSet {
            abi.p.relaxedVerification = relaxedVerification
        }
    }

    public var systemAppearance: SystemAppearance? {
        didSet {
            ui.set(systemAppearance?.rawValue, forUIPreference: .systemAppearance)
            applyAppearance()
        }
    }
}

// MARK: - Appearance

extension UserPreferencesObservable {
    public func applyAppearance() {
#if os(iOS)
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene else {
            return
        }
        guard let window = scene.keyWindow else {
            return
        }
        switch systemAppearance {
        case .light:
            window.overrideUserInterfaceStyle = .light
        case .dark:
            window.overrideUserInterfaceStyle = .dark
        case .none:
            window.overrideUserInterfaceStyle = .unspecified
        }
#elseif os(macOS)
        guard let app = NSApp else {
//            assertionFailure("NSApp is being used too early")
            return
        }
        switch systemAppearance {
        case .light:
            app.appearance = NSAppearance(named: .vibrantLight)
        case .dark:
            app.appearance = NSAppearance(named: .vibrantDark)
        case .none:
            app.appearance = nil
        }
#endif
    }
}

private extension UserDefaults {
    func set<V>(_ value: V?, forUIPreference pref: UIPreference) {
        set(value, forKey: pref.key)
    }

    func string(forUIPreference pref: UIPreference) -> String? {
        string(forKey: pref.key)
    }

    func bool(forUIPreference pref: UIPreference) -> Bool {
        bool(forKey: pref.key)
    }

    func integer(forUIPreference pref: UIPreference) -> Int {
        integer(forKey: pref.key)
    }

    func double(forUIPreference pref: UIPreference) -> Double {
        double(forKey: pref.key)
    }

    func data(forUIPreference pref: UIPreference) -> Data? {
        data(forKey: pref.key)
    }

    func object(forUIPreference pref: UIPreference) -> Any? {
        object(forKey: pref.key)
    }
}
