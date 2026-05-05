// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonLibrary
import SwiftUI

struct PreferencesAdvancedView: View {
    @Environment(ConfigObservable.self)
    private var configObservable

    @Environment(IAPObservable.self)
    private var iapObservable

    @Environment(\.appConfiguration)
    private var appConfiguration

    @Binding
    var experimental: ABI.AppPreferenceValues.Experimental

    var body: some View {
        Form {
            configSection
        }
        .themeForm()
    }
}

private enum ConfigFlagPreference: String, CaseIterable, Identifiable {
    case remote
    case enable
    case disable

    var id: Self {
        self
    }
}

private extension PreferencesAdvancedView {
    static let flags: [ABI.ConfigFlag] = [
        .bsdSockets,
        .newProfileEncoding,
        .ovpnCrossV2,
        .wgCrossV2
    ]

    var canOverride: Bool {
        iapObservable.isBeta || appConfiguration.bundle.distributionTarget == .developerID
    }

    @ViewBuilder
    var configSection: some View {
        if canOverride {
            overrideSection
        } else {
            remoteSection
        }
    }

    var overrideSection: some View {
        ForEach(Self.flags, id: \.rawValue) { flag in
            configPicker(for: flag)
        }
        .themeSection(
            footer: Strings.Views.Preferences.Advanced.Override.footer
        )
    }

    var remoteSection: some View {
        ForEach(Self.flags, id: \.rawValue) { flag in
            configToggle(for: flag)
        }
        .themeSection(
            header: Strings.Global.Actions.allow,
            footer: Strings.Views.Preferences.Advanced.Remote.footer
        )
    }

    func configPicker(for flag: ABI.ConfigFlag) -> some View {
        Picker(selection: preferenceBinding(for: flag)) {
            ForEach(ConfigFlagPreference.allCases) { pref in
                Text(pref.localizedDescription)
                    .tag(pref)
            }
        } label: {
            flagView(for: flag)
        }
    }

    func configToggle(for flag: ABI.ConfigFlag) -> some View {
        Toggle(isOn: isAllowedBinding(for: flag)) {
            flagView(for: flag)
        }
    }

    func isAllowedBinding(for flag: ABI.ConfigFlag) -> Binding<Bool> {
        Binding {
            experimental.isAllowed(flag)
        } set: {
            experimental.setAllowed(flag, isAllowed: $0)
        }
    }

    func preferenceBinding(for flag: ABI.ConfigFlag) -> Binding<ConfigFlagPreference> {
        Binding {
            experimental.preference(for: flag)
        } set: {
            experimental.setPreference($0, for: flag)
        }
    }

    func flagView(for flag: ABI.ConfigFlag) -> some View {
        VStack(alignment: .leading) {
            Text(flag.localizedDescription)
            Text(configObservable.isActive(flag) ? Strings.Global.Nouns.enabled : Strings.Global.Nouns.disabled)
                .themeSubtitle()
        }
    }
}

private extension ABI.AppPreferenceValues.Experimental {
    func isAllowed(_ flag: ABI.ConfigFlag) -> Bool {
        !ignoredConfigFlags.contains(flag)
    }

    mutating func setAllowed(_ flag: ABI.ConfigFlag, isAllowed: Bool) {
        if isAllowed {
            ignoredConfigFlags.remove(flag)
        } else {
            ignoredConfigFlags.insert(flag)
        }
    }

    func preference(for flag: ABI.ConfigFlag) -> ConfigFlagPreference {
        if ignoredConfigFlags.contains(flag) {
            return .disable
        }
        if enabledConfigFlags.contains(flag) {
            return .enable
        }
        return .remote
    }

    mutating func setPreference(_ preference: ConfigFlagPreference, for flag: ABI.ConfigFlag) {
        ignoredConfigFlags.remove(flag)
        enabledConfigFlags.remove(flag)

        switch preference {
        case .enable:
            enabledConfigFlags.insert(flag)
        case .disable:
            ignoredConfigFlags.insert(flag)
        case .remote:
            break
        }
    }
}

// MARK: - Localization

private extension ABI.ConfigFlag {
    var localizedDescription: String {
        rawValue
    }
}

private extension ConfigFlagPreference {
    var localizedDescription: String {
        switch self {
        case .remote:
            return Strings.Views.Preferences.Advanced.Override.Picker.remote
        case .enable:
            return Strings.Global.Actions.enable
        case .disable:
            return Strings.Global.Actions.disable
        }
    }
}
