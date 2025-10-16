// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonProvidersCore
import Foundation

public final class InMemoryProviderRepository: ProviderRepository {
    public let providerId: ProviderID

    private let allPresets: [ProviderPreset]

    private let allServers: [ProviderServer]

    public init(
        providerId: ProviderID,
        allPresets: [ProviderPreset],
        allServers: [ProviderServer]
    ) {
        self.providerId = providerId
        self.allPresets = allPresets
        self.allServers = allServers
    }

    public func availableOptions(for moduleType: ModuleType) async throws -> ProviderFilterOptions {
        var countriesByCategoryName: [String: Set<String>] = [:]
        allServers.forEach {
            var codes = countriesByCategoryName[$0.metadata.categoryName] ?? Set()
            codes.insert($0.metadata.countryCode)
            countriesByCategoryName[$0.metadata.categoryName] = codes
        }

        let countryCodes = allServers
            .map(\.metadata.countryCode)

        let presets = allPresets
            .filter {
                $0.moduleType == moduleType
            }

        return .init(
            countriesByCategoryName: countriesByCategoryName,
            countryCodes: Set(countryCodes),
            presets: Set(presets)
        )
    }

    public func filteredServers(with parameters: ProviderServerParameters?) async -> [ProviderServer] {
        let all = allServers
        return await Task.detached {
            var servers: [ProviderServer]
            if let parameters {
                servers = all
                    .filter { server in
                        parameters.filters.matches(server)
                    }

                // this may be VERY slow
                if !parameters.sorting.isEmpty {
                    servers.sort(using: parameters.sortingComparators)
                }
            } else {
                servers = all
            }
            return servers
        }.value
    }
}

// MARK: - Processing

private extension ProviderFilters {
    func matches(_ server: ProviderServer) -> Bool {
        if let moduleType, let supportedModuleTypes = server.supportedModuleTypes {
            guard supportedModuleTypes.contains(moduleType) else {
                return false
            }
        }
        if let categoryName {
            guard server.metadata.categoryName == categoryName else {
                return false
            }
        }
        if let countryCode {
//            guard !countryCodes.isDisjoint(with: server.provider.countryCodes) else {
            guard server.metadata.countryCode == countryCode else {
                return false
            }
        }
        if let presetId, let supportedPresetIds = server.supportedPresetIds {
            guard supportedPresetIds.contains(presetId) else {
                return false
            }
        }
        if let area {
            guard server.metadata.area == area else {
                return false
            }
        }
        if let serverIds {
            guard serverIds.contains(server.serverId) else {
                return false
            }
        }
        return true
    }
}

private extension ProviderServerParameters {
    var sortingComparators: [KeyPathComparator<ProviderServer>] {
        sorting
            .map {
                switch $0 {
                case .localizedCountry:
                    return KeyPathComparator(\.localizedCountry)

                case .area:
                    return KeyPathComparator(\.metadata.area)

                case .serverId:
                    return KeyPathComparator(\.serverId)
                }
            }
    }
}
