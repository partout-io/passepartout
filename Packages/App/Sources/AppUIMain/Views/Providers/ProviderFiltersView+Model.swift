//
//  ProviderFiltersView+Model.swift
//  Passepartout
//
//  Created by Davide De Rosa on 10/26/24.
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
import Foundation
import UIAccessibility

extension ProviderFiltersView {

    @MainActor
    final class Model: ObservableObject {
        typealias CodeWithDescription = (code: String, description: String)

        private let defaults: UserDefaults

        private var options: ProviderFilterOptions

        @Published
        private(set) var categories: [String]

        @Published
        private(set) var countries: [CodeWithDescription]

        @Published
        private(set) var presets: [ProviderPreset]

        @Published
        var filters: ProviderFilters

        @Published
        var onlyShowsFavorites: Bool

        private var subscriptions: Set<AnyCancellable>

        init(defaults: UserDefaults = .standard) {
            self.defaults = defaults
            options = ProviderFilterOptions()
            categories = []
            countries = []
            presets = []
            filters = ProviderFilters()
            onlyShowsFavorites = false
            subscriptions = []

            if !AppCommandLine.contains(.uiTesting) {
                observeObjects()
            }
        }

        func load(options: ProviderFilterOptions, initialFilters: ProviderFilters?) {
            self.options = options
            setCategories(withNames: Set(options.countriesByCategoryName.keys))
            setCountries(withCodes: options.countryCodes)
            setPresets(with: options.presets)

            if let initialFilters {
                filters = initialFilters
            }
        }

        func update(with servers: [ProviderServer]) {

            // only countries that have servers in this category
            let knownCountryCodes: Set<String>
            if let categoryName = filters.categoryName {
                knownCountryCodes = options.countriesByCategoryName[categoryName] ?? []
            } else {
                knownCountryCodes = options.countryCodes
            }

            // only presets known in filtered servers
            var knownPresets = options.presets
            let allPresetIds = Set(servers.compactMap(\.supportedPresetIds).joined())
            if !allPresetIds.isEmpty {
                knownPresets = knownPresets
                    .filter {
                        allPresetIds.contains($0.presetId)
                    }
            }

            setCountries(withCodes: knownCountryCodes)
            setPresets(with: knownPresets)
        }
    }
}

private extension ProviderFiltersView.Model {
    func setCategories(withNames categoryNames: Set<String>) {
        categories = categoryNames
            .sorted()
    }

    func setCountries(withCodes codes: Set<String>) {
        countries = codes
            .map(\.asCountryCodeWithDescription)
            .sorted {
                $0.description < $1.description
            }
    }

    func setPresets(with presets: Set<ProviderPreset>) {
        self.presets = presets
            .sorted {
                $0.description < $1.description
            }
    }
}

// MARK: - Observation

private extension ProviderFiltersView.Model {
    func observeObjects() {
        $onlyShowsFavorites
            .dropFirst()
            .sink { [weak self] in
                self?.defaults.onlyShowsFavorites = $0
            }
            .store(in: &subscriptions)

        // send initial value
        onlyShowsFavorites = defaults.onlyShowsFavorites
    }
}

// MARK: -

private extension UserDefaults {
    var onlyShowsFavorites: Bool {
        get {
            bool(forKey: UIPreference.onlyShowsFavorites.key)
        }
        set {
            set(newValue, forKey: UIPreference.onlyShowsFavorites.key)
        }
    }
}

private extension String {
    var asCountryCodeWithDescription: ProviderFiltersView.Model.CodeWithDescription {
        (self, localizedAsRegionCode ?? self)
    }
}
