// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonLibrary
import SwiftUI

extension ProfileEditor {
    public subscript<T>(module: T) -> ModuleDraft<T> where T: ModuleBuilder {
        ModuleDraft(editor: self, module: module)
    }
}

// MARK: - Shortcuts

extension ProfileEditor {
    public func shortcutsSections(path: Binding<NavigationPath>) -> some View {
        ForEach(shortcutsProviders, id: \.id) {
            if $0.isVisible {
                AnyView($0.moduleShortcutsView(editor: self, path: path))
                    .themeSection(header: $0.moduleType.localizedDescription)
            }
        }
    }

    private var shortcutsProviders: [any ModuleShortcutsProviding] {
        modules.compactMap {
            $0 as? any ModuleShortcutsProviding
        }
    }
}

// MARK: - ModulePreferences

extension ProfileEditor {
    public func excludedEndpoints(for moduleId: UUID, preferences: ModulePreferences) -> ObservableList<ExtendedEndpoint> {
        ObservableList { [weak self] endpoint in
            self?.profile.attributes.preference(inModule: moduleId) {
                $0.isExcludedEndpoint(endpoint)
            } ?? false
        } add: { [weak self] endpoint in
            self?.profile.attributes.editPreferences(inModule: moduleId) {
                $0.addExcludedEndpoint(endpoint)
            }
            preferences.addExcludedEndpoint(endpoint)
        } remove: { [weak self] endpoint in
            self?.profile.attributes.editPreferences(inModule: moduleId) {
                $0.removeExcludedEndpoint(endpoint)
            }
            preferences.removeExcludedEndpoint(endpoint)
        }
    }
}
