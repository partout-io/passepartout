// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#if canImport(Combine)
import Combine
extension ProviderManager: ObservableObject {
}
#endif

import Partout

@MainActor
public final class ProviderManager {
    private let sorting: [ProviderSortField]

    public private(set) var moduleType: ModuleType

    private var repository: ProviderRepository

    public private(set) var options: ProviderFilterOptions

    private var filterTask: Task<[ProviderServer], Error>?

    public init(sorting: [ProviderSortField] = []) {
        self.sorting = sorting
        moduleType = ModuleType("")
        repository = DummyRepository()
        options = ProviderFilterOptions()
    }
}

extension ProviderManager {
    public func setRepository(_ repository: ProviderRepository, for moduleType: ModuleType) async throws {
        self.moduleType = moduleType
        self.repository = repository
        options = try await repository.availableOptions(for: moduleType)
#if canImport(Combine)
        objectWillChange.send()
#endif
    }

    public var providerId: ProviderID {
        guard !(repository is DummyRepository) else {
            fatalError("Call setRepository() first")
        }
        return repository.providerId
    }

    public var presets: [ProviderPreset] {
        Array(options.presets.filter {
            $0.moduleType == moduleType
        })
    }

    public func filteredServers(with filters: ProviderFilters? = nil) async throws -> [ProviderServer] {
        if let filterTask {
            _ = try await filterTask.value
        }
        filterTask = Task {
            try await rawApplyFilters(filters)
        }
        let servers = try await filterTask!.value
        filterTask = nil
        return servers
    }
}

private extension ProviderManager {
    func rawApplyFilters(_ filters: ProviderFilters?) async throws -> [ProviderServer] {
        var parameters = ProviderServerParameters(sorting: sorting)
        if let filters {
            parameters.filters = filters
            parameters.filters.moduleType = moduleType
        }
        return try await repository.filteredServers(with: parameters)
    }
}

// MARK: - Dummy

private final class DummyRepository: ProviderRepository {
    let providerId = ProviderID(rawValue: "")

    func availableOptions(for moduleType: ModuleType) async throws -> ProviderFilterOptions {
        ProviderFilterOptions()
    }

    func filteredServers(with parameters: ProviderServerParameters?) -> [ProviderServer] {
        []
    }
}
