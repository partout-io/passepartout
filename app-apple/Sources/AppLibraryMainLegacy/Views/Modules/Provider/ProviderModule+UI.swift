// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonLibrary
import SwiftUI

extension ProviderModule.Builder: LegacyModuleViewProviding {
    public func moduleView(with parameters: LegacyModuleViewParameters) -> some View {
        ProviderView(draft: parameters.editor[self])
    }
}

// MARK: - Destination

extension ProviderModule {
    enum Subroute: Hashable {
        case server

//        case preset

        case openVPNCredentials
    }
}

extension ProviderModule.Builder: ModuleDestinationProviding {
    public func handlesRoute(_ route: AnyHashable) -> Bool {
        route is ProviderModule.Subroute
    }

    public func moduleDestination(
        for route: AnyHashable,
        path: Binding<NavigationPath>,
        editor: ProfileEditor
    ) -> some View {
        (route as? ProviderModule.Subroute)
            .map {
                DestinationView(route: $0, draft: editor[self], path: path)
            }
    }
}

private struct DestinationView: View {
    let route: ProviderModule.Subroute

    @ObservedObject
    var draft: ModuleDraft<ProviderModule.Builder>

    @Binding
    var path: NavigationPath

    var body: some View {
        Group {
            switch route {
            case .server:
                module.map {
                    ProviderServerView(
                        module: $0,
                        onSelect: {
                            draft.module.entity = $0
                            path.removeLast()
                        }
                    )
                }

            case .openVPNCredentials:
                ProviderView.OpenVPNCredentialsView(draft: draft)
            }
        }
    }

    // FIXME: #1470, heavy data copy in SwiftUI
    private var module: ProviderModule? {
        try? draft.module.build()
    }
}

// MARK: - Shortcuts

extension ProviderModule.Builder: ModuleShortcutsProviding {
    public var isVisible: Bool {
        providerId != nil && providerModuleType != nil
    }

    @ViewBuilder
    public func moduleShortcutsView(editor: ProfileEditor, path: Binding<NavigationPath>) -> some View {
        if let providerId {
            ProviderNameRow(id: providerId)
        }
        ProviderServerLink(entity: entity)
        switch providerModuleType {
        case .openVPN:
            ProviderView.OpenVPNCredentialsLink()
        default:
            EmptyView()
        }
    }
}
