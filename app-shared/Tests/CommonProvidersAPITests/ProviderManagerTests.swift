// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonProvidersAPI
import CommonProvidersCore
import Partout
import Testing

@MainActor
struct ProviderManagerTests {

    @Test
    func givenManager_whenFetchSupportedPresets_thenIsNotEmpty() async throws {
        let repository = try await Self.repository(for: .mock)
        let sut = ProviderManager()
        try await sut.setRepository(repository, for: MockModule.moduleHandler.id)

        print(sut.presets)
        #expect(sut.presets.count == 1)
    }

    @Test
    func givenManager_whenFetchUnsupportedPresets_thenIsEmpty() async throws {
        let repository = try await Self.repository(for: .mock)
        let sut = ProviderManager()
        try await sut.setRepository(repository, for: MockUnsupportedModule.moduleHandler.id)

        print(sut.presets)
        #expect(sut.presets.isEmpty)
    }

    @Test
    func givenManager_whenSetProvider_thenReturnsServers() async throws {
        let repository = try await Self.repository(for: .mock)
        let sut = ProviderManager()
        try await sut.setRepository(repository, for: MockModule.moduleHandler.id)

        #expect(sut.options.countryCodes.count == 1)
        let servers = try await sut.filteredServers()
        #expect(servers.count == 1)

        let server = try #require(servers.first)
        #expect(server.metadata.countryCode == "US")

        let ipAddresses = server.ipAddresses?.compactMap {
            Address(data: $0)
        } ?? []
        #expect(ipAddresses.map(\.rawValue) == ["1.2.3.4"])
    }

    @Test
    func givenManager_whenSetFilters_thenReturnsFilteredServers() async throws {
        let repository = try await Self.repository(for: .mock)
        let sut = ProviderManager()
        try await sut.setRepository(repository, for: MockModule.moduleHandler.id)

        var filters = ProviderFilters()
        filters.categoryName = "foobar"
        let servers = try await sut.filteredServers(with: filters)
        #expect(servers.isEmpty)
    }

    @Test
    func givenManager_whenSetFiltersThenReset_thenReturnsAllServers() async throws {
        let repository = try await Self.repository(for: .mock)
        let sut = ProviderManager()
        try await sut.setRepository(repository, for: MockModule.moduleHandler.id)

        var filters = ProviderFilters()
        filters.categoryName = "foobar"
        var servers = try await sut.filteredServers(with: filters)
        servers = try await sut.filteredServers()
        #expect(servers.count == 1)
    }
}

// MARK: -

@MainActor
private extension ProviderManagerTests {
    static func yield() async {
        try? await Task.sleep(milliseconds: 100)
    }

    static func repository(for providerId: ProviderID) async throws -> ProviderRepository {
        do {
            let api = MockAPI()
            let repository = MockRepository()

            let providerManager = APIManager(.global, from: [api], repository: repository)
            let module = try ProviderModule(emptyWithProviderId: .mock)
            try await providerManager.fetchInfrastructure(for: module)

            return repository.providerRepository(for: providerId, sort: { _, _ in })
        } catch {
            print("Unable to fetch API: \(error)")
            throw error
        }
    }
}
