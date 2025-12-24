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
    }

    public var dnsFallsBack: Bool {
        get {
            kvStore.bool(forAppPreference: .dnsFallsBack)
        }
        set {
            kvStore.set(newValue, forAppPreference: .dnsFallsBack)
        }
    }

    public var keepsInMenu: Bool {
        get {
            kvStore.bool(forUIPreference: .keepsInMenu)
        }
        set {
            kvStore.set(newValue, forUIPreference: .keepsInMenu)
        }
    }

    public var lastInfrastructureRefresh: [String: TimeInterval]? {
        get {
            kvStore.object(forUIPreference: .lastInfrastructureRefresh) as [String: TimeInterval]?
        }
        set {
            kvStore.set(newValue, forUIPreference: .lastInfrastructureRefresh)
        }
    }

    public var logsPrivateData: Bool {
        get {
            kvStore.bool(forAppPreference: .logsPrivateData)
        }
        set {
            kvStore.set(newValue, forAppPreference: .logsPrivateData)
        }
    }

    public var onboardingStep: OnboardingStep? {
        get {
            guard let rawValue = kvStore.string(forUIPreference: .onboardingStep) else {
                return nil
            }
            return OnboardingStep(rawValue: rawValue)
        }
        set {
            guard let newValue else {
                kvStore.set(nil as String?, forUIPreference: .onboardingStep)
                return
            }
            kvStore.set(newValue.rawValue, forUIPreference: .onboardingStep)
        }
    }

    public var onlyShowsFavorites: Bool {
        get {
            kvStore.bool(forUIPreference: .onlyShowsFavorites)
        }
        set {
            kvStore.set(newValue, forUIPreference: .onlyShowsFavorites)
        }
    }

    public var relaxedVerification: Bool {
        get {
            kvStore.bool(forAppPreference: .relaxedVerification)
        }
        set {
            kvStore.set(newValue, forAppPreference: .relaxedVerification)
        }
    }

    public var systemAppearance: SystemAppearance? {
        get {
            guard let rawValue = kvStore.string(forUIPreference: .systemAppearance) else {
                return nil
            }
            return SystemAppearance(rawValue: rawValue)
        }
        set {
            kvStore.set(newValue?.rawValue, forUIPreference: .systemAppearance)
            applyAppearance()
        }
    }
}

extension UserPreferencesObservable {
    public struct Experimental: Hashable, Codable, Sendable {
        public var ignoredConfigFlags: Set<ABI.ConfigFlag> = []
    }

    public var experimental: Experimental {
        get {
            guard let experimentalData = kvStore.object(forAppPreference: .experimental) as Data? else {
                return Experimental()
            }
            do {
                return try JSONDecoder().decode(Experimental.self, from: experimentalData)
            } catch {
                pp_log_g(.App.core, .error, "Unable to decode experimental: \(error)")
                return Experimental()
            }
        }
        set {
            do {
                let experimentalData = try JSONEncoder().encode(newValue)
                kvStore.set(experimentalData, forAppPreference: .experimental)
            } catch {
                pp_log_g(.App.core, .error, "Unable to encode experimental: \(error)")
            }
        }
    }
}

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

private extension KeyValueStore {
    func object<T>(forUIPreference pref: UIPreference) -> T? {
        object(forKey: pref.key)
    }

    func set<T>(_ value: T?, forUIPreference pref: UIPreference) {
        set(value, forKey: pref.key)
    }
}
