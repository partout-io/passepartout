// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#if os(macOS)

import CommonLibrary
import SwiftUI

extension ProviderServerView {
    struct ContentView: View {

        @Environment(Theme.self)
        private var theme

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
        private var hoveringServerId: String?

        var body: some View {
            debugChanges()
            return serversTable
        }
    }
}

private extension ProviderServerView.ContentView {
    var serversTable: some View {
        // TODO: #1263, servers.regions is inefficient, fetch regions directly
        Table(servers.regions) {
            TableColumn("") { region in
                ThemeImage(.marked)
                    .opaque(region.isSelected(by: heuristic))
                    .environment(theme) // TODO: #873, Table loses environment
            }
            .width(10.0)

            TableColumn("☆") { region in
                ThemeFavoriteToggle(
                    value: region.id,
                    selection: providerPreferences.favoriteServers()
                )
                .environment(theme) // TODO: #873, Table loses environment
            }
            .width(15.0)

            TableColumn(Strings.Global.Nouns.country) { region in
                Button {
                    let heuristic: ProviderHeuristic
                    if region.area != nil {
                        heuristic = .sameRegion(region)
                    } else {
                        heuristic = .sameCountry(region.countryCode)
                    }
                    guard let randomServer = servers.randomServer(using: heuristic) else {
                        return
                    }
                    onSelect(randomServer, heuristic)
                } label: {
                    ThemeCountryText(region.countryCode)
                }
                .help(region.localizedDescription)
                .cursor(.hand)
                .environment(theme) // TODO: #873, Table loses environment
            }

            TableColumn(Strings.Global.Nouns.region) { region in
                Button {
                    let heuristic: ProviderHeuristic = .sameRegion(region)
                    guard let randomServer = servers.randomServer(using: heuristic) else {
                        return
                    }
                    onSelect(randomServer, heuristic)
                } label: {
                    region.area.map(Text.init)
                }
                .help(region.area ?? "")
                .cursor(.hand)
                .environment(theme) // TODO: #873, Table loses environment
            }
        }
    }
}

#endif
