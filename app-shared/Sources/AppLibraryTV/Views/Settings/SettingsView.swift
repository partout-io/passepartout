// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonLibrary

import SwiftUI

struct SettingsView: View {

    @EnvironmentObject
    private var iapManager: IAPManager

    @ObservedObject
    var profileManager: ProfileManager

    let tunnel: ExtendedTunnel

    @FocusState
    private var focus: Detail?

    @State
    private var detail: Detail?

    var body: some View {
        HStack {
            masterView
                .frame(maxWidth: .infinity)
                .focused($focus, equals: .other)

            DetailView(detail: detail)
                .frame(maxWidth: .infinity)
        }
        .themeGradient()
        .onChange(of: focus) {
            guard focus != nil else {
                return
            }
            detail = focus
        }
    }
}

private extension SettingsView {
    var masterView: some View {
        List {
            if iapManager.isBeta {
                BetaSection()
            } else {
                VersionUpdateLink()
            }
            creditsSection
            preferencesSection
            troubleshootingSection
        }
        .themeList()
    }

    var creditsSection: some View {
        Group {
            Button {
            } label: {
                ThemeRow(
                    Strings.Global.Nouns.version,
                    value: BundleConfiguration.mainVersionString
                )
            }
            .focused($focus, equals: .version)
            Button(Strings.Views.Settings.Credits.title) {}
                .focused($focus, equals: .credits)
            Button(Strings.Views.Donate.title) {}
                .focused($focus, equals: .donate)
        }
        .themeSection(header: Strings.Views.Settings.title)
    }

    var preferencesSection: some View {
        PreferencesView(profileManager: profileManager)
    }

    var troubleshootingSection: some View {
        Group {
            NavigationLink(Strings.Views.Diagnostics.Rows.app, value: AppCoordinatorRoute.appLog)
            NavigationLink(Strings.Views.Diagnostics.Rows.tunnel, value: AppCoordinatorRoute.tunnelLog)
            LogsPrivateDataToggle()
            Button(Strings.Views.Purchased.title) {}
                .focused($focus, equals: .purchased)
        }
        .themeSection(header: Strings.Global.Nouns.troubleshooting)
    }
}

// MARK: - Detail

private enum Detail {
    case credits

    case donate

    case other

    case preferences

    case purchased

    case version
}

private struct DetailView: View {
    let detail: Detail?

    var body: some View {
        switch detail {
        case .credits:
            CreditsView()
                .themeList()

        case .donate:
            DonateView(modifier: DonateViewModifier())

        case .purchased:
            PurchasedView()
                .themeList()

        case .version:
            VersionView()

        default:
            VStack {}
        }
    }
}

// MARK: - Preview

#Preview {
    SettingsView(
        profileManager: .forPreviews,
        tunnel: .forPreviews
    )
    .themeNavigationStack()
    .withMockEnvironment()
}
