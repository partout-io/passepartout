// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#if os(macOS)

import CommonLibrary
import CommonResources
import SwiftUI

struct SettingsContentView<LinkContent, SettingsDestination, DiagnosticsDestination>: View where LinkContent: View, SettingsDestination: View, DiagnosticsDestination: View {

    @Environment(\.distributionTarget)
    private var distributionTarget

    @Environment(\.dismiss)
    private var dismiss

    let profileManager: ProfileManager

    let isBeta: Bool

    @Binding
    var path: NavigationPath

    @Binding
    var navigationRoute: SettingsCoordinatorRoute?

    let linkContent: (SettingsCoordinatorRoute) -> LinkContent

    let settingsDestination: (SettingsCoordinatorRoute?) -> SettingsDestination

    let diagnosticsDestination: (DiagnosticsRoute?) -> DiagnosticsDestination

    var body: some View {
        NavigationSplitView {
            listView
        } detail: {
            settingsDestination(navigationRoute)
                .navigationDestination(for: SettingsCoordinatorRoute.self, destination: settingsDestination)
                .navigationDestination(for: DiagnosticsRoute.self, destination: diagnosticsDestination)
                .themeNavigationStack(closable: false, path: $path)
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button(Strings.Global.Nouns.ok) {
                            dismiss()
                        }
                    }
                }
        }
        .onLoad {
            navigationRoute = .preferences
        }
    }
}

private extension SettingsContentView {
    var listView: some View {
        List(selection: $navigationRoute) {
            Group {
                linkContent(.preferences)
                VersionUpdateLink()
            }
            Group {
                linkContent(.version)
                linkContent(.links)
                linkContent(.credits)
                if !isBeta && distributionTarget.supportsIAP {
                    linkContent(.donate)
                }
            }
            .themeSection(header: Strings.Global.Nouns.about)

            Group {
                ExternalLink(Strings.Unlocalized.faq, url: Resources.constants.websites.faq)
                if distributionTarget == .developerID {
                    linkContent(.systemExtension)
                }
                linkContent(.diagnostics)
                if distributionTarget.supportsIAP {
                    linkContent(.purchased)
                }
            }
            .themeSection(header: Strings.Global.Nouns.troubleshooting)
        }
        .safeAreaInset(edge: .bottom) {
            Text(BundleConfiguration.mainVersionString)
                .padding(.bottom)
        }
        .navigationTitle(Strings.Views.Settings.title)
    }
}

#endif
