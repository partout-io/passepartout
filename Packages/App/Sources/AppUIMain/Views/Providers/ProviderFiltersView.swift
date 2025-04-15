//
//  ProviderFiltersView.swift
//  Passepartout
//
//  Created by Davide De Rosa on 10/9/24.
//  Copyright (c) 2025 Davide De Rosa. All rights reserved.
//
//  https://github.com/passepartoutvpn
//
//  This file is part of Passepartout.
//
//  Passepartout is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  Passepartout is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with Passepartout.  If not, see <http://www.gnu.org/licenses/>.
//

import Combine
import CommonLibrary
import SwiftUI

struct ProviderFiltersView: View {
    let providerId: ProviderID

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
                    .frame(maxWidth: .infinity, alignment: .center)
#else
                HStack {
                    favoritesToggle
                    Spacer()
                    RefreshInfrastructureButton(providerId: providerId)
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

#Preview {
    NavigationStack {
        ProviderFiltersView(
            providerId: .mullvad,
            model: .init(),
            heuristic: .constant(nil)
        )
    }
}
