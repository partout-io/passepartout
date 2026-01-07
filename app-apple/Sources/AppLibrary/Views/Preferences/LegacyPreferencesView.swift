// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonLibrary
import Partout
import SwiftUI

#if !os(tvOS)

@available(*, deprecated, message: "#1594")
public struct LegacyPreferencesView: View {
    @Environment(UserPreferencesObservable.self)
    private var userPreferences

    @EnvironmentObject
    private var iapManager: IAPManager

    @Environment(ConfigObservable.self)
    private var configObservable

#if os(macOS)
    @Environment(MacSettings.self)
    private var settings
#endif

    @Environment(\.appConfiguration)
    private var appConfiguration

    private let profileManager: ProfileManager

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
            if appConfiguration.distributionTarget.supportsIAP {
                enablesPurchasesSection
            }
            if appConfiguration.distributionTarget.supportsIAP &&
                configObservable.isActive(.allowsRelaxedVerification) {
                relaxedVerificationSection
            }
            if appConfiguration.distributionTarget.supportsCloudKit {
                eraseCloudKitSection
            }
            NavigationLink(advancedTitle, destination: advancedView)
        }
        .themeForm()
    }
}

private extension LegacyPreferencesView {
    static let systemAppearances: [SystemAppearance?] = [
        nil,
        .light,
        .dark
    ]

    var systemAppearanceSection: some View {
        Section {
            Picker(Strings.Views.Preferences.systemAppearance, selection: userPreferences.binding(\.systemAppearance)) {
                ForEach(Self.systemAppearances, id: \.self) {
                    Text($0?.localizedDescription ?? Strings.Entities.Ui.SystemAppearance.system)
                }
            }
        }
    }

#if os(iOS)
    var lockInBackgroundSection: some View {
        Toggle(Strings.Views.Preferences.locksInBackground, isOn: userPreferences.binding(\.locksInBackground))
            .themeContainerEntry(subtitle: Strings.Views.Preferences.LocksInBackground.footer)
    }

#elseif os(macOS)
    var launchesOnLoginSection: some View {
        Toggle(Strings.Views.Preferences.launchesOnLogin, isOn: settings.binding(\.launchesOnLogin))
            .themeContainerEntry(subtitle: Strings.Views.Preferences.LaunchesOnLogin.footer)
    }

    var keepsInMenuSection: some View {
        Toggle(Strings.Views.Preferences.keepsInMenu, isOn: userPreferences.binding(\.keepsInMenu))
            .themeContainerEntry(subtitle: Strings.Views.Preferences.KeepsInMenu.footer)
    }
#endif

    var pinActiveProfileSection: some View {
        PinActiveProfileToggle()
            .themeContainerEntry(subtitle: Strings.Views.Preferences.PinsActiveProfile.footer)
    }

    var dnsFallsBackSection: some View {
        Toggle(Strings.Views.Preferences.dnsFallsBack, isOn: userPreferences.binding(\.dnsFallsBack))
            .themeContainerEntry(subtitle: Strings.Views.Preferences.DnsFallsBack.footer)
    }

    var enablesPurchasesSection: some View {
        Toggle(Strings.Views.Preferences.enablesIap, isOn: $iapManager.isEnabled)
            .themeContainerEntry(subtitle: Strings.Views.Preferences.EnablesIap.footer)
    }

    var relaxedVerificationSection: some View {
        Toggle(Strings.Views.Preferences.relaxedVerification, isOn: userPreferences.binding(\.relaxedVerification))
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
        PreferencesAdvancedView(experimental: userPreferences.binding(\.experimental))
            .navigationTitle(advancedTitle)
    }
}

#else

public struct LegacyPreferencesView: View {
    @Environment(UserPreferencesObservable.self)
    private var userPreferences

    @Environment(ConfigObservable.self)
    private var configObservable

    @Environment(\.appConfiguration)
    private var appConfiguration

    private let profileManager: ProfileManager

    public init(profileManager: ProfileManager) {
        self.profileManager = profileManager
    }

    public var body: some View {
        Group {
            if appConfiguration.distributionTarget.supportsIAP &&
                configObservable.isActive(.allowsRelaxedVerification) {
                relaxedVerificationToggle
            }
        }
        .themeSection(header: Strings.Global.Nouns.preferences)
    }
}

private extension LegacyPreferencesView {
    var relaxedVerificationToggle: some View {
        Toggle(Strings.Views.Preferences.relaxedVerification, isOn: userPreferences.binding(\.relaxedVerification))
    }
}

#endif

#Preview {
    LegacyPreferencesView(profileManager: .forPreviews)
        .withMockEnvironment()
#if os(macOS)
        .environment(MacSettings())
#endif
}
