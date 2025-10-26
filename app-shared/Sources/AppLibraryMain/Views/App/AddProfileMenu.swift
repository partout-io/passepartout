// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonLibrary
import SwiftUI

struct AddProfileMenu: View {

    @EnvironmentObject
    private var apiManager: APIManager

    @Environment(\.distributionTarget)
    private var distributionTarget

    let profileManager: ProfileManager

    let registry: Registry

    @Binding
    var isImporting: Bool

    let onNewProfile: (EditableProfile) -> Void

    var body: some View {
        Menu {
            emptyProfileButton
            importProfileButton
            if distributionTarget.supportsPaidFeatures {
                Divider()
                providerProfileMenu
            }
        } label: {
            ThemeImage(.add)
        }
    }
}

private extension AddProfileMenu {
    var emptyProfileButton: some View {
        Button {
            let editable = EditableProfile(name: newName)
            onNewProfile(editable)
        } label: {
            ThemeImageLabel(Strings.Views.App.Toolbar.NewProfile.empty, .profileEdit)
        }
    }

    var importProfileButton: some View {
        Button {
            isImporting = true
        } label: {
            ThemeImageLabel(Strings.Views.App.Toolbar.importProfile.forMenu, .profileImport)
        }
    }

    var providerProfileMenu: some View {
        Menu {
            ForEach(supportedProviders, content: providerSubmenu(for:))
        } label: {
            ThemeImageLabel(Strings.Views.App.Toolbar.NewProfile.provider, .profileProvider)
        }
    }

    func providerSubmenu(for provider: Provider) -> some View {
        ProviderSubmenu(
            provider: provider,
            registry: registry,
            onSelect: {
                var copy = $0
                copy.name = profileManager.firstUniqueName(from: copy.name)
                onNewProfile(copy)
            }
        )
    }
}

private extension AddProfileMenu {
    var newName: String {
        profileManager.firstUniqueName(from: Strings.Placeholders.Profile.name)
    }

    var supportedProviders: [Provider] {
        apiManager.providers
    }
}

// MARK: - Providers

private struct ProviderSubmenu: View {
    let provider: Provider

    let registry: Registry

    let onSelect: (EditableProfile) -> Void

    var body: some View {
        Menu {
            ForEach(Array(sortedTypes), id: \.self, content: profileButton(for:))
        } label: {
            Text(provider.description)
        }
    }

    func profileButton(for moduleType: ModuleType) -> some View {
        Button(moduleType.localizedDescription) {
            var editable = EditableProfile()
            editable.name = provider.description
            var moduleBuilder = ProviderModule.Builder()
            moduleBuilder.providerId = provider.id
            moduleBuilder.providerModuleType = moduleType
            editable.modules.append(moduleBuilder)
            let onDemandBuilder = OnDemandModule.Builder()
            editable.modules.append(onDemandBuilder)
            editable.activeModulesIds = Set(editable.modules.map(\.id))
            onSelect(editable)
        }
    }

    private var sortedTypes: [ModuleType] {
        provider.metadata.keys
            .sorted {
                $0.localizedDescription < $1.localizedDescription
            }
    }
}
