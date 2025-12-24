// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import AppAccessibility
import Combine
import CommonLibrary
import Foundation

extension ProviderFiltersView {

    // FIXME: #1594, Requires $onlyShowsFavorites publisher
    @MainActor
    final class Model: ObservableObject {
        typealias CodeWithDescription = (code: String, description: String)

        private let userPreferences: UserPreferencesObservable

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

        init(userPreferences: UserPreferencesObservable) {
            self.userPreferences = userPreferences
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
                self?.userPreferences.onlyShowsFavorites = $0
            }
            .store(in: &subscriptions)

        // Send initial value
        onlyShowsFavorites = userPreferences.onlyShowsFavorites
    }
}

// MARK: -

private extension String {
    var asCountryCodeWithDescription: ProviderFiltersView.Model.CodeWithDescription {
        (self, localizedAsRegionCode ?? self)
    }
}
