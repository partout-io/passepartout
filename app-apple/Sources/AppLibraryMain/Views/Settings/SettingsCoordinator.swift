// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonLibrary
import SwiftUI

struct SettingsCoordinator: View {
    @Environment(IAPObservable.self)
    private var iapObservable

    @Environment(\.appConfiguration)
    private var appConfiguration

    @Environment(\.logFormatterBlock)
    private var logFormatterBlock

    @Environment(\.dismiss)
    private var dismiss

    let profileObservable: ProfileObservable

    let tunnel: TunnelObservable

    @State
    private var path = NavigationPath()

    @State
    private var navigationRoute: SettingsCoordinatorRoute?

    var body: some View {
        SettingsContentView(
            profileObservable: profileObservable,
            isBeta: iapObservable.isBeta,
            path: $path,
            navigationRoute: $navigationRoute,
            linkContent: linkView(to:),
            settingsDestination: pushDestination(for:),
            diagnosticsDestination: pushDestination(for:)
        )
    }
}

extension SettingsCoordinator {
    func linkView(to route: SettingsCoordinatorRoute) -> some View {
        NavigationLink(value: route) {
            linkLabel(for: route)
        }
    }

    func title(for route: SettingsCoordinatorRoute) -> String {
        switch route {
        case .changelog:
            Strings.Unlocalized.changelog
        case .credits:
            Strings.Views.Settings.Credits.title
        case .diagnostics:
            Strings.Views.Diagnostics.title
        case .donate:
            Strings.Views.Donate.title
        case .links:
            Strings.Views.Settings.Links.title
        case .preferences:
            Strings.Global.Nouns.preferences
        case .purchased:
            Strings.Global.Nouns.purchases
        case .systemExtension:
            Strings.Global.Nouns.Apple.systemExtension
        case .version:
            Strings.Views.Settings.title
        }
    }

    @ViewBuilder
    func linkLabel(for route: SettingsCoordinatorRoute) -> some View {
        switch route {
        case .version:
            Text(Strings.Global.Nouns.version)
#if os(iOS)
                .themeTrailingValue(appConfiguration.versionString)
#endif

        default:
            Text(title(for: route))
        }
    }

    @ViewBuilder
    func pushDestination(for item: SettingsCoordinatorRoute?) -> some View {
        switch item {
        case .changelog:
            ChangelogView()
                .navigationTitle(title(for: .changelog))

        case .credits:
            CreditsView()
                .navigationTitle(title(for: .credits))

        case .diagnostics:
            DiagnosticsView(profileObservable: profileObservable, tunnel: tunnel)
                .navigationTitle(title(for: .diagnostics))

        case .donate:
            DonateView(modifier: DonateViewModifier())
                .navigationTitle(title(for: .donate))

        case .links:
            LinksView(isBeta: iapObservable.isBeta)
                .navigationTitle(title(for: .links))

        case .preferences:
            PreferencesView(profileObservable: profileObservable)
                .navigationTitle(title(for: .preferences))

        case .purchased:
            PurchasedView()
                .navigationTitle(Strings.Global.Nouns.purchases)

#if os(macOS)
        case .systemExtension:
            SystemExtensionView()
                .navigationTitle(Strings.Global.Nouns.Apple.systemExtension)
#endif

        case .version:
            VersionView(changelogRoute: SettingsCoordinatorRoute.changelog)

        default:
            Text(Strings.Global.Nouns.noSelection)
                .themeEmptyMessage()
        }
    }

    @ViewBuilder
    func pushDestination(for item: DiagnosticsRoute?) -> some View {
        switch item {
        case .appLog(let title):
            DebugLogView(
                withAppParameters: appConfiguration.constants.log,
                content: {
                    DebugLogContentView(lines: $0)
                }
            )
            .navigationTitle(title)

        case .profile(let profile):
            DiagnosticsProfileView(tunnel: tunnel, profile: profile)

        case .tunnelLog(let title, let url):
            if let url {
                DebugLogView(withURL: url) {
                    DebugLogContentView(lines: $0)
                }
                .navigationTitle(title)
            } else {
                DebugLogView(
                    withTunnel: tunnel,
                    content: {
                        DebugLogContentView(lines: $0)
                    }
                )
                .navigationTitle(title)
            }

        default:
            Text(Strings.Global.Nouns.noSelection)
                .themeEmptyMessage()
        }
    }
}

#Preview {
    SettingsCoordinator(
        profileObservable: .forPreviews,
        tunnel: .forPreviews
    )
    .withMockEnvironment()
#if os(macOS)
    .environment(MacSettings())
#endif
}
