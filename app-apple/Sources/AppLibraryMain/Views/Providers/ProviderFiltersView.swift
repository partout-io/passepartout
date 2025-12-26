// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import Combine
import CommonLibrary
import SwiftUI

struct ProviderFiltersView: View {

    // FIXME: #1470, heavy data copy in SwiftUI
    let module: ProviderModule

    @ObservedObject
    var model: Model

    @Binding
    var heuristic: ProviderHeuristic?

    var body: some View {
        debugChanges()
        return Form {
            Section {
                categoryPicker
                countryPicker
                presetPicker
#if os(iOS)
                clearFiltersButton
                    .themeActionButton()
#else
                HStack {
                    favoritesToggle
                    Spacer()
                    RefreshInfrastructureButton(module: module)
                    clearFiltersButton
                }
#endif
            }
        }
    }
}

private extension ProviderFiltersView {
    var categoryNameBinding: Binding<String?> {
        Binding {
            model.filters.categoryName
        } set: {
            model.filters.categoryName = $0
            model.filters.countryCode = nil
        }
    }

    var categoryPicker: some View {
        Picker(Strings.Global.Nouns.category, selection: categoryNameBinding) {
            Text(Strings.Global.Nouns.any)
                .tag(nil as String?)
            ForEach(model.categories, id: \.self) {
                Text($0)
                    .tag($0 as String?)
            }
        }
    }

    var countryPicker: some View {
        Picker(Strings.Global.Nouns.country, selection: $model.filters.countryCode) {
            Text(Strings.Global.Nouns.any)
                .tag(nil as String?)
            ForEach(model.countries, id: \.code) {
                Text($0.description)
                    .tag($0.code as String?)
            }
        }
    }

    var presetPicker: some View {
        Picker(Strings.Views.Providers.preset, selection: $model.filters.presetId) {
            Text(Strings.Global.Nouns.any)
                .tag(nil as String?)
            ForEach(model.presets, id: \.presetId) {
                Text($0.description)
                    .tag($0.presetId as String?)
            }
        }
    }

    var favoritesToggle: some View {
        Toggle(Strings.Views.Providers.onlyFavorites, isOn: $model.onlyShowsFavorites)
    }

    var clearFiltersButton: some View {
        Button(Strings.Views.Providers.clearFilters, role: .destructive) {
            model.filters = ProviderFilters()
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        ProviderFiltersView(
            module: ProviderID.mullvad.asPreviewModule,
            model: .init(userPreferences: UserPreferencesObservable(kvStore: InMemoryStore())),
            heuristic: .constant(nil)
        )
    }
}
