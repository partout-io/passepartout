// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#if os(iOS)

import AppAccessibility
import CommonLibrary
import SwiftUI

extension ProviderServerView {
    struct ContentView: View {

        // FIXME: #1470, heavy data copy in SwiftUI
        let module: ProviderModule

        let servers: [ProviderServer]

        @Binding
        var heuristic: ProviderHeuristic?

        let isFiltering: Bool

        @ObservedObject
        var filtersViewModel: ProviderFiltersView.Model

        @ObservedObject
        var providerPreferences: ProviderPreferences

        let selectTitle: String

        let onSelect: (ProviderServer, ProviderHeuristic?) -> Void

        @State
        private var regionsByCountryCode: [String: [ProviderRegion]] = [:]

        @State
        private var expandedCodes: Set<String> = []

        var body: some View {
            debugChanges()
            return listView
                .themeAnimation(on: isFiltering, category: .providers)
                .onChange(of: servers, perform: computeServersByCountry)
        }
    }
}

private extension ProviderServerView.ContentView {
    var listView: some View {
        List {
            Section {
                Toggle(Strings.Views.Providers.onlyFavorites, isOn: $filtersViewModel.onlyShowsFavorites)
                RefreshInfrastructureButton(module: module)
            }
            Group {
                if isFiltering || !servers.isEmpty {
                    if isFiltering {
                        ProgressView()
                            .id(UUID())
                    } else {
                        ForEach(countryCodes, id: \.self, content: countryView)
                    }
                } else {
                    emptyView
                }
            }
            .themeSection(
                header: filtersViewModel.filters.categoryName ?? Strings.Views.Vpn.Category.any
            )
            .onLoad {
                if let selectedServer = module.entity?.server {
                    expandedCodes.insert(selectedServer.metadata.countryCode)
                }
            }
        }
    }

    func countryView(for code: String) -> some View {
        regionsByCountryCode[code]
            .map { regions in
                Group {
                    if regions.count > 1 {
                        DisclosureGroup(isExpanded: isExpandedCountry(code)) {
                            ForEach(regions, id: \.id, content: regionView)
                        } label: {
                            HStack {
                                ThemeCountryText(code)
                                Spacer()
                                ThemeImage(.marked)
                                    .opaque(code.isCountryCodeSelected(by: heuristic))
                            }
                        }
                        .uiAccessibility(.ProviderServers.countryGroup)
                    } else if let singleRegion = regions.first {
                        regionView(for: singleRegion, isSingle: true)
                    }
                }
            }
    }

    func regionView(for region: ProviderRegion) -> some View {
        regionView(for: region, isSingle: false)
    }

    func regionView(for region: ProviderRegion, isSingle: Bool) -> some View {
        Button {
            let heuristic: ProviderHeuristic
            if !isSingle && region.area != nil {
                heuristic = .sameRegion(region)
            } else {
                heuristic = .sameCountry(region.countryCode)
            }
            guard let randomServer = servers.randomServer(using: heuristic) else {
                return
            }
            onSelect(randomServer, heuristic)
        } label: {
            HStack {
                if isSingle {
                    ThemeCountryText(region.countryCode, title: region.localizedDescription)
                } else if let area = region.area {
                    Text(area)
                } else {
                    Text(Strings.Global.Nouns.any)
                }
                Spacer()
                ThemeImage(.marked)
                    .opaque(region.isSelected(by: heuristic))
                ThemeFavoriteToggle(
                    value: region.id,
                    selection: providerPreferences.favoriteServers()
                )
            }
        }
        .foregroundStyle(.primary)
    }

    var emptyView: some View {
        Text(Strings.Views.Vpn.noServers)
    }
}

private extension ProviderServerView.ContentView {
    var countryCodes: [String] {
        filtersViewModel
            .countries
            .map(\.code)
    }

    func isExpandedCountry(_ code: String) -> Binding<Bool> {
        Binding {
            expandedCodes.contains(code)
        } set: {
            if $0 {
                expandedCodes.insert(code)
            } else {
                expandedCodes.remove(code)
            }
        }
    }

    // TODO: #1263, servers.regions is inefficient, fetch regions directly
    func computeServersByCountry(_ servers: [ProviderServer]) {
        let regions = servers.regions
        var map: [String: [ProviderRegion]] = [:]
        regions.forEach {
            let code = $0.countryCode
            var list = map[code] ?? []
            list.append($0)
            map[code] = list
        }
        regionsByCountryCode = map
    }
}

#endif
