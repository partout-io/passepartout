// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonLibrary
import SwiftUI

struct ProviderServerView: View {

    @EnvironmentObject
    private var apiManager: APIManager

    @EnvironmentObject
    private var preferencesManager: PreferencesManager

    // FIXME: #1470, heavy data copy in SwiftUI
    let module: ProviderModule

    var selectTitle = Strings.Views.Providers.selectEntity

    let onSelect: (ProviderEntity) -> Void

    @StateObject
    private var providerManager = ProviderManager(
        sorting: [
            .localizedCountry,
            .area,
            .serverId
        ]
    )

    @State
    private var servers: [ProviderServer] = []

    @State
    private var isFiltering = false

    @State
    private var onlyShowsFavorites = false

    @State
    private var heuristic: ProviderHeuristic?

    @StateObject
    private var providerPreferences = ProviderPreferences()

    @StateObject
    private var filtersViewModel = ProviderFiltersView.Model(
        userPreferences: UserPreferencesObservable(
            kvStore: UserDefaultsStore(.standard)
        )
    )

    @State
    private var errorHandler: ErrorHandler = .default()

    var body: some View {
        debugChanges()
        return ContainerView(
            content: contentView,
            filters: filtersView
        )
        .navigationTitle(title)
        .themeNavigationDetail()
        .withErrorHandler(errorHandler)
    }
}

extension ProviderServerView {
    func contentView() -> some View {
        ContentView(
            module: module,
            servers: filteredServers,
            heuristic: $heuristic,
            isFiltering: isFiltering,
            filtersViewModel: filtersViewModel,
            providerPreferences: providerPreferences,
            selectTitle: selectTitle,
            onSelect: onSelectServer
        )
        .onLoad {
            heuristic = module.entity?.heuristic
        }
        .task {
            await loadInitialServers()
        }
        .onReceive(filtersViewModel.$filters.dropFirst(), perform: onNewFilters)
        .onReceive(filtersViewModel.$onlyShowsFavorites, perform: onToggleFavorites)
        .onDisappear(perform: onDisappear)
    }

    func filtersView() -> some View {
        ProviderFiltersView(
            module: module,
            model: filtersViewModel,
            heuristic: $heuristic
        )
    }
}

private extension ProviderServerView {
    var providerId: ProviderID {
        module.providerId
    }

    var moduleType: ModuleType {
        module.providerModuleType
    }

    var title: String {
        apiManager.provider(withId: providerId)?.description ?? Strings.Global.Nouns.servers
    }

    var filteredServers: [ProviderServer] {
        if onlyShowsFavorites {
            return servers.filter {
                providerPreferences.isFavoriteServer($0.regionId)
            }
        }
        return servers
    }

    var initialFilters: ProviderFilters? {
        guard let selectedEntity = module.entity else {
            return nil
        }
        var filters = ProviderFilters()
        filters.presetId = selectedEntity.preset.presetId
        return filters
    }

    func loadInitialServers() async {
        do {
            let repository = try preferencesManager.preferencesRepository(forProviderWithId: providerId)
            providerPreferences.setRepository(repository)
        } catch {
            pspLog(.core, .error, "Unable to load preferences for provider \(providerId): \(error)")
        }
        do {
            let repository = try await apiManager.providerRepository(for: module) {
                guard !$1.isEmpty else { return }
                $0.sort(using: $1.sortingComparators)
            }
            try await providerManager.setRepository(repository, for: moduleType)
            filtersViewModel.load(options: providerManager.options, initialFilters: initialFilters)
            await reloadServers(filters: filtersViewModel.filters)
        } catch {
            pspLog(.core, .error, "Unable to load VPN servers for provider \(providerId): \(error)")
            errorHandler.handle(error, title: Strings.Global.Nouns.servers)
        }
    }

    func reloadServers(filters: ProviderFilters) async {
        isFiltering = true
        do {
            try await Task {
                servers = try await providerManager.filteredServers(with: filters)
                filtersViewModel.update(with: servers)
                isFiltering = false
            }.value
        } catch {
            pspLog(.core, .error, "Unable to fetch filtered servers: \(error)")
        }
    }

    func compatiblePresets(with server: ProviderServer) -> [ProviderPreset] {
        providerManager
            .presets
            .filter {
                if let selectedId = filtersViewModel.filters.presetId {
                    return $0.presetId == selectedId
                }
                return true
            }
            .filter {
                if let supportedIds = server.supportedPresetIds {
                    return supportedIds.contains($0.presetId)
                }
                return true
            }
    }

    func onNewFilters(_ filters: ProviderFilters) {
        Task {
            await reloadServers(filters: filters)
        }
    }

    func onToggleFavorites(_ only: Bool) {
        onlyShowsFavorites = only
    }

    func onDisappear() {
        do {
            try providerPreferences.save()
        } catch {
            pspLog(.core, .error, "Unable to save preferences: \(error)")
        }
    }

    func onSelectServer(_ server: ProviderServer, heuristic: ProviderHeuristic?) {
        let presets = compatiblePresets(with: server)
        guard let preset = presets.first else {
            pspLog(.core, .error, "Unable to find a compatible preset. Supported IDs: \(server.supportedPresetIds?.description ?? "all")")
            assertionFailure("No compatible presets for server \(server.serverId) (provider=\(providerManager.providerId), moduleType=\(providerManager.moduleType), supported=\(server.supportedPresetIds ?? []))")
            return
        }
        let entity = ProviderEntity(server: server, preset: preset, heuristic: heuristic)
        onSelect(entity)
    }
}

// MARK: - Preview

extension ProviderID {
    var asPreviewModule: ProviderModule {
        do {
            return try ProviderModule.Builder(providerId: self).build()
        } catch {
            fatalError(error.localizedDescription)
        }
    }
}

#Preview {
    NavigationStack {
        ProviderServerView(
            module: ProviderID.hideme.asPreviewModule,
            selectTitle: "Select",
            onSelect: { _ in }
        )
    }
    .withMockEnvironment()
}
