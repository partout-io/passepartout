// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonLibrary
import Observation
import SwiftUI

@MainActor @Observable
public final class UserPreferencesObservable {
    private let kvStore: KeyValueStore

    public init(kvStore: KeyValueStore) {
        self.kvStore = kvStore

        dnsFallsBack = kvStore.bool(forAppPreference: .dnsFallsBack)
        experimental = kvStore.object(forAppPreference: .experimental) as ABI.AppPreferenceValues.Experimental? ?? ABI.AppPreferenceValues.Experimental()
        keepsInMenu = kvStore.bool(forUIPreference: .keepsInMenu)
        lastInfrastructureRefresh = kvStore.object(forUIPreference: .lastInfrastructureRefresh) as [String: TimeInterval]?
        locksInBackground = kvStore.bool(forUIPreference: .locksInBackground)
        logsPrivateData = kvStore.bool(forAppPreference: .logsPrivateData)
        onboardingStep = kvStore.string(forUIPreference: .onboardingStep).flatMap {
            OnboardingStep(rawValue: $0)
        }
        onlyShowsFavorites = kvStore.bool(forUIPreference: .onlyShowsFavorites)
        pinsActiveProfile = kvStore.bool(forUIPreference: .pinsActiveProfile)
        profilesLayout = kvStore.string(forUIPreference: .profilesLayout).flatMap {
            ProfilesLayout(rawValue: $0)
        } ?? .list
        relaxedVerification = kvStore.bool(forAppPreference: .relaxedVerification)
        systemAppearance = kvStore.string(forUIPreference: .systemAppearance).flatMap {
            SystemAppearance(rawValue: $0)
        }
    }

    // MARK: Preferences

    public var dnsFallsBack: Bool {
        didSet {
            kvStore.set(dnsFallsBack, forAppPreference: .dnsFallsBack)
        }
    }

    public var experimental: ABI.AppPreferenceValues.Experimental {
        didSet {
            kvStore.set(experimental, forAppPreference: .experimental)
        }
    }

    public var keepsInMenu: Bool {
        didSet {
            kvStore.set(keepsInMenu, forUIPreference: .keepsInMenu)
        }
    }

    public var lastInfrastructureRefresh: [String: TimeInterval]? {
        didSet {
            kvStore.set(lastInfrastructureRefresh, forUIPreference: .lastInfrastructureRefresh)
        }
    }

    public var locksInBackground: Bool {
        didSet {
            kvStore.set(locksInBackground, forUIPreference: .locksInBackground)
        }
    }

    public var logsPrivateData: Bool {
        didSet {
            kvStore.set(logsPrivateData, forAppPreference: .logsPrivateData)
        }
    }

    public var onboardingStep: OnboardingStep? {
        didSet {
            kvStore.set(onboardingStep?.rawValue, forUIPreference: .onboardingStep)
        }
    }

    public var onlyShowsFavorites: Bool {
        didSet {
            kvStore.set(onlyShowsFavorites, forUIPreference: .onlyShowsFavorites)
        }
    }

    public var pinsActiveProfile: Bool {
        didSet {
            kvStore.set(pinsActiveProfile, forUIPreference: .pinsActiveProfile)
        }
    }

    public var profilesLayout: ProfilesLayout {
        didSet {
            kvStore.set(profilesLayout.rawValue, forUIPreference: .profilesLayout)
        }
    }

    public var relaxedVerification: Bool {
        didSet {
            kvStore.set(relaxedVerification, forAppPreference: .relaxedVerification)
        }
    }

    public var systemAppearance: SystemAppearance? {
        didSet {
            kvStore.set(systemAppearance?.rawValue, forUIPreference: .systemAppearance)
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
