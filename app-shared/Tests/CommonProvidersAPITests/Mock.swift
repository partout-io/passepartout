// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonProvidersAPI
import CommonProvidersCore
import Partout

struct MockModule: Module {
    static let moduleHandler = ModuleHandler(ModuleType("mock-module"), decoder: nil, factory: nil)

    var supportedField = 123
}

struct MockUnsupportedModule: Module {
    static let moduleHandler = ModuleHandler(ModuleType("mock-unsupported-module"), decoder: nil, factory: nil)

    let unsupportedField: Int
}

extension ProviderID {
    static let mock = ProviderID(rawValue: "mock-provider")
}

struct MockAPI: APIMapper {
    func index() async throws -> [Provider] {
        [
            Provider("foo1", description: "bar1"),
            Provider("foo2", description: "bar2", moduleTypes: [MockModule.self]),
            Provider("foo3", description: "bar3")
        ]
    }

    func authenticate(_ module: ProviderModule, on deviceId: String) async throws -> ProviderModule {
        module
    }

    func infrastructure(for module: ProviderModule, cache: ProviderCache?) async throws -> ProviderInfrastructure {
        ProviderInfrastructure(
            presets: [
                ProviderPreset(
                    providerId: .mock,
                    presetId: "default",
                    description: "MockPreset",
                    moduleType: ModuleType("mock-module"),
                    templateData: Data()
                )
            ],
            servers: [.mock],
            cache: nil
        )
    }
}

final class MockRepository: APIRepository {
    private let providersSubject = CurrentValueStream<UniqueID, [Provider]>([])

    private let infrastructuresSubject = CurrentValueStream<UniqueID, [ProviderID: ProviderInfrastructure]>([:])

    var indexStream: AsyncStream<[Provider]> {
        providersSubject.subscribe()
    }

    var cacheStream: AsyncStream<[ProviderID: ProviderCache]> {
        infrastructuresSubject
            .subscribe()
            .map {
                $0.compactMapValues(\.cache)
            }
    }

    func store(_ providers: [Provider]) async throws {
        providersSubject.send(providers)
    }

    func store(_ infrastructure: ProviderInfrastructure, for providerId: ProviderID) async throws {
        var newValue = infrastructuresSubject.value
        newValue[providerId] = infrastructure
        infrastructuresSubject.send(newValue)
    }

    func presets(for server: ProviderServer, moduleType: ModuleType) async throws -> [ProviderPreset] {
        []
    }

    func providerRepository(for providerId: ProviderID, sort: @escaping ProviderServerParameters.Sorter) -> ProviderRepository {
        let infra = infrastructuresSubject.value[providerId]
        let repo = MockVPNRepository(providerId: providerId)
        repo.allServers = infra?.servers ?? []
        repo.allPresets = infra?.presets ?? []
        return repo
    }

    func resetCache(for providerIds: [ProviderID]?) async {
    }
}

final class MockVPNRepository: ProviderRepository, @unchecked Sendable {
    let providerId: ProviderID

    var allServers: [ProviderServer] = []

    var allPresets: [ProviderPreset] = []

    init(providerId: ProviderID) {
        self.providerId = providerId
    }

    func availableOptions(for moduleType: ModuleType) async throws -> ProviderFilterOptions {
        let allCategoryNames = Set(allServers.map(\.metadata.categoryName))
        let allCountryCodes = Set(allServers.map(\.metadata.countryCode))
        return ProviderFilterOptions(
            countriesByCategoryName: allCategoryNames.reduce(into: [:]) {
                $0[$1] = allCountryCodes
            },
            countryCodes: allCountryCodes,
            presets: Set(allPresets)
        )
    }

    func filteredServers(with parameters: ProviderServerParameters?) async -> [ProviderServer] {
        if parameters?.filters.categoryName != nil {
            return []
        }
        return allServers
    }
}

extension ProviderServer {
    static var mock: ProviderServer {
        ProviderServer(
            metadata: .init(
                providerId: .mock,
                categoryName: "Default",
                countryCode: "US",
                otherCountryCodes: nil,
                area: nil
            ),
            serverId: "mock",
            hostname: "mock-hostname.com",
            ipAddresses: [Data(hex: "01020304")],
            supportedModuleTypes: [MockModule.moduleHandler.id],
            supportedPresetIds: []
        )
    }
}
