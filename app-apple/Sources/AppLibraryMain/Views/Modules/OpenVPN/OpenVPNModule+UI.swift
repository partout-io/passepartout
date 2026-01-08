// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonLibrary
import SwiftUI

extension OpenVPNModule.Builder: ModuleViewProviding {
    public func moduleView(with editor: ProfileEditor) -> some View {
        OpenVPNView(draft: editor[self])
    }
}

// MARK: - Destination

extension OpenVPNModule {
    enum Subroute: Hashable {
        case credentials

        case remotes
    }
}

extension OpenVPNModule.Builder: ModuleDestinationProviding {
    public func handlesRoute(_ route: AnyHashable) -> Bool {
        route is OpenVPNModule.Subroute
    }

    public func moduleDestination(
        for route: AnyHashable,
        path: Binding<NavigationPath>,
        editor: ProfileEditor
    ) -> some View {
        (route as? OpenVPNModule.Subroute)
            .map {
                DestinationView(route: $0, path: path, editor: editor, draft: editor[self])
            }
    }
}

private struct DestinationView: View {
    let route: OpenVPNModule.Subroute

    @Binding
    var path: NavigationPath

    let editor: ProfileEditor

    @ObservedObject
    var draft: ModuleDraft<OpenVPNModule.Builder>

    @StateObject
    private var preferences = ModulePreferences()

    var body: some View {
        Group {
            switch route {
            case .credentials:
                Form {
                    OpenVPNCredentialsGroup(draft: draft)
                }
                .navigationTitle(Strings.Modules.Openvpn.credentials)
                .themeForm()
                .themeAnimation(on: draft.module.isInteractive, category: .modules)

            case .remotes:
                OpenVPNView.RemotesView(
                    configuration: configurationBuilderBinding,
                    excludedEndpoints: excludedEndpoints,
                    isEditable: true
                )
            }
        }
        .modifier(ModulePreferencesModifier(
            moduleId: draft.module.id,
            preferences: preferences
        ))
    }
}

private extension DestinationView {
    var configurationBuilderBinding: Binding<OpenVPN.Configuration.Builder> {
        Binding {
            draft.module.configurationBuilder ?? OpenVPN.Configuration.Builder()
        } set: {
            draft.module.configurationBuilder = $0
        }
    }

    var excludedEndpoints: ObservableList<ExtendedEndpoint> {
        editor.excludedEndpoints(for: draft.module.id, preferences: preferences)
    }
}

// MARK: - Shortcuts

extension OpenVPNModule.Builder: ModuleShortcutsProviding {
    public var isVisible: Bool {
        configurationBuilder?.authUserPass == true
    }

    @ViewBuilder
    public func moduleShortcutsView(editor: ProfileEditor, path: Binding<NavigationPath>) -> some View {
        if configurationBuilder?.authUserPass == true {
            ProfileLink(
                Strings.Modules.Openvpn.credentials,
                route: OpenVPNModule.Subroute.credentials
            )
        }
    }
}
