// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#if os(iOS)

import CommonLibrary
import SwiftUI

struct SettingsContentView<LinkContent, SettingsDestination, LogDestination>: View where LinkContent: View, SettingsDestination: View, LogDestination: View {
    @Environment(\.appConfiguration)
    private var appConfiguration

    @Environment(\.dismiss)
    private var dismiss

    let profileObservable: ProfileObservable

    let isBeta: Bool

    @Binding
    var path: NavigationPath

    @Binding
    var navigationRoute: SettingsCoordinatorRoute?

    let linkContent: (SettingsCoordinatorRoute) -> LinkContent

    let settingsDestination: (SettingsCoordinatorRoute?) -> SettingsDestination

    let diagnosticsDestination: (DiagnosticsRoute?) -> LogDestination

    var body: some View {
        listView
            .navigationDestination(for: SettingsCoordinatorRoute.self, destination: settingsDestination)
            .navigationDestination(for: DiagnosticsRoute.self, destination: diagnosticsDestination)
            .themeNavigationDetail()
            .themeNavigationStack(closable: true, path: $path)
    }
}

private extension SettingsContentView {
    var listView: some View {
        List {
            Group {
                linkContent(.preferences)
                linkContent(.version)
                VersionUpdateLink()
            }
            .themeSection(header: Strings.Global.Nouns.about)
            Group {
                linkContent(.links)
                linkContent(.credits)
                if !isBeta && appConfiguration.distributionTarget.supportsIAP {
                    linkContent(.donate)
                }
            }
            .themeSection(header: Strings.Global.Nouns.about)

            ExternalLink(Strings.Unlocalized.faq, url: appConfiguration.constants.websites.faq)
                .themeSection(header: Strings.Global.Nouns.troubleshooting)

            Group {
                linkContent(.diagnostics)
                if appConfiguration.distributionTarget.supportsIAP {
                    linkContent(.purchased)
                }
            }
            .themeSection()
        }
        .navigationTitle(Strings.Global.Nouns.settings)
    }
}

#endif
