// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonLibrary
import Partout
import SwiftUI

#if !os(tvOS)

public struct PreferencesView: View {

    @Environment(AppearanceObservable.self)
    private var appearanceObservable

    @EnvironmentObject
    private var iapManager: IAPManager

    @EnvironmentObject
    private var kvManager: KeyValueManager

    @EnvironmentObject
    private var configManager: ConfigManager

#if os(iOS)
    @AppStorage(ABI.UIPreference.locksInBackground.key)
    private var locksInBackground = false
#elseif os(macOS)
    @EnvironmentObject
    private var settings: MacSettingsModel
#endif

    @Environment(\.distributionTarget)
    private var distributionTarget

    private let profileManager: ProfileManager

    @State
    private var preferences = ABI.AppPreferenceValues()

    @State
    private var isConfirmingEraseiCloud = false

    @State
    private var isErasingiCloud = false

    public init(profileManager: ProfileManager) {
        self.profileManager = profileManager
    }

    public var body: some View {
        Form {
            systemAppearanceSection
#if os(iOS)
            lockInBackgroundSection
#elseif os(macOS)
            launchesOnLoginSection
            keepsInMenuSection
#endif
            pinActiveProfileSection
            dnsFallsBackSection
            if distributionTarget.supportsIAP {
                enablesPurchasesSection
            }
            if distributionTarget.supportsIAP && configManager.isActive(.allowsRelaxedVerification) {
                relaxedVerificationSection
            }
            if distributionTarget.supportsCloudKit {
                eraseCloudKitSection
            }
            NavigationLink(advancedTitle, destination: advancedView)
        }
        .themeForm()
        // These bindings are necessary to propagate the changes to the KeyValueManager
        .onLoad {
            preferences = kvManager.preferences
        }
        .onChange(of: preferences) {
            kvManager.preferences = $0
        }
    }
}

private extension PreferencesView {
    static let systemAppearances: [SystemAppearance?] = [
        nil,
        .light,
        .dark
    ]

    var systemAppearanceSection: some View {
        Section {
            Picker(Strings.Views.Preferences.systemAppearance, selection: appearanceObservable.binding(\.systemAppearance)) {
                ForEach(Self.systemAppearances, id: \.self) {
                    Text($0?.localizedDescription ?? Strings.Entities.Ui.SystemAppearance.system)
                }
            }
        }
    }

#if os(iOS)
    var lockInBackgroundSection: some View {
        Toggle(Strings.Views.Preferences.locksInBackground, isOn: $locksInBackground)
            .themeContainerEntry(subtitle: Strings.Views.Preferences.LocksInBackground.footer)
    }

#elseif os(macOS)
    var launchesOnLoginSection: some View {
        Toggle(Strings.Views.Preferences.launchesOnLogin, isOn: $settings.launchesOnLogin)
            .themeContainerEntry(subtitle: Strings.Views.Preferences.LaunchesOnLogin.footer)
    }

    var keepsInMenuSection: some View {
        Toggle(Strings.Views.Preferences.keepsInMenu, isOn: $settings.keepsInMenu)
            .themeContainerEntry(subtitle: Strings.Views.Preferences.KeepsInMenu.footer)
    }
#endif

    var pinActiveProfileSection: some View {
        PinActiveProfileToggle()
            .themeContainerEntry(subtitle: Strings.Views.Preferences.PinsActiveProfile.footer)
    }

    var dnsFallsBackSection: some View {
        Toggle(Strings.Views.Preferences.dnsFallsBack, isOn: $preferences.dnsFallsBack)
            .themeContainerEntry(subtitle: Strings.Views.Preferences.DnsFallsBack.footer)
    }

    var enablesPurchasesSection: some View {
        Toggle(Strings.Views.Preferences.enablesIap, isOn: $iapManager.isEnabled)
            .themeContainerEntry(subtitle: Strings.Views.Preferences.EnablesIap.footer)
    }

    var relaxedVerificationSection: some View {
        Toggle(Strings.Views.Preferences.relaxedVerification, isOn: $preferences.relaxedVerification)
    }

    var eraseCloudKitSection: some View {
        Button(Strings.Views.Preferences.eraseIcloud, role: .destructive) {
            isConfirmingEraseiCloud = true
        }
        .themeConfirmation(
            isPresented: $isConfirmingEraseiCloud,
            title: Strings.Views.Preferences.eraseIcloud,
            isDestructive: true
        ) {
            isErasingiCloud = true
            Task {
                do {
                    pp_log_g(.App.core, .info, "Erase CloudKit profiles...")
                    try await profileManager.eraseRemotelySharedProfiles()
                } catch {
                    pp_log_g(.App.core, .error, "Unable to erase CloudKit store: \(error)")
                }
                isErasingiCloud = false
            }
        }
        .themeContainerWithSingleEntry(
            header: Strings.Unlocalized.iCloud,
            footer: Strings.Views.Preferences.EraseIcloud.footer,
            isAction: true
        )
        .disabled(isErasingiCloud)
    }

    var advancedTitle: String {
        Strings.Global.Nouns.advanced
    }

    func advancedView() -> some View {
        PreferencesAdvancedView(experimental: $preferences.experimental)
            .navigationTitle(advancedTitle)
            .onChange(of: preferences.experimental) {
                kvManager.preferences.experimental = $0
            }
    }
}

#else

public struct PreferencesView: View {

    @EnvironmentObject
    private var kvManager: KeyValueManager

    @EnvironmentObject
    private var configManager: ConfigManager

    @Environment(\.distributionTarget)
    private var distributionTarget

    private let profileManager: ProfileManager

    @State
    private var relaxedVerification = false

    public init(profileManager: ProfileManager) {
        self.profileManager = profileManager
    }

    public var body: some View {
        Group {
            if distributionTarget.supportsIAP && configManager.isActive(.allowsRelaxedVerification) {
                relaxedVerificationToggle
            }
        }
        .themeSection(header: Strings.Global.Nouns.preferences)
        .themeKeyValue(kvManager, ABI.AppPreference.relaxedVerification.key, $relaxedVerification, default: false)
    }
}

private extension PreferencesView {
    var relaxedVerificationToggle: some View {
        Toggle(Strings.Views.Preferences.relaxedVerification, isOn: $relaxedVerification)
    }
}

#endif

#Preview {
    PreferencesView(profileManager: .forPreviews)
        .withMockEnvironment()
#if os(macOS)
        .environmentObject(MacSettingsModel())
#endif
}
