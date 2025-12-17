// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

public final class InMemoryAPIRepository: APIRepositoryReader, APIRepositoryWriter {
    private let ctx: PartoutLoggerContext

    private let providersSubject: CurrentValueStream<UniqueID, [Provider]>

    private let infrastructuresSubject: CurrentValueStream<UniqueID, [ProviderID: ProviderInfrastructure]>

    public init(_ ctx: PartoutLoggerContext) {
        self.ctx = ctx
        providersSubject = CurrentValueStream([])
        infrastructuresSubject = CurrentValueStream([:])
    }

    // MARK: ProviderRepositoryReader

    public var indexStream: AsyncStream<[Provider]> {
        providersSubject.subscribe()
    }

    public var cacheStream: AsyncStream<[ProviderID: ProviderCache]> {
        infrastructuresSubject
            .subscribe()
            .map {
                $0.compactMapValues(\.cache)
            }
    }

    public func presets(for server: ProviderServer, moduleType: ModuleType) async throws -> [ProviderPreset] {
        guard let infra = infrastructuresSubject.value[server.metadata.providerId] else {
            return []
        }
        if let supported = server.supportedPresetIds {
            return infra.presets.filter {
                supported.contains($0.presetId)
            }
        }
        return infra.presets
    }

    public func providerRepository(for providerId: ProviderID, sort: @escaping ProviderServerParameters.Sorter) -> ProviderRepository {
        let infra = infrastructuresSubject.value[providerId]
        let servers = infra?.servers ?? []
        let presets = infra?.presets ?? []
        return InMemoryProviderRepository(
            providerId: providerId,
            allPresets: presets,
            allServers: servers,
            sort: sort
        )
    }

    // MARK: ProviderRepositoryWriter

    public func store(_ providers: [Provider]) {
        providersSubject.send(providers)
    }

    public func store(_ infrastructure: ProviderInfrastructure, for providerId: ProviderID) {
        if let newDate = infrastructure.cache?.lastUpdate,
           let currentDate = infrastructuresSubject.value[providerId]?.cache?.lastUpdate {
            guard newDate > currentDate else {
                pp_log(ctx, .providers, .info, "Discard infrastructure older than stored one (\(newDate) <= \(currentDate))")
                return
            }
        }
        var newValue = infrastructuresSubject.value
        newValue[providerId] = infrastructure
        infrastructuresSubject.send(newValue)
    }

    public func resetCache(for providerIds: [ProviderID]?) async {
        if let providerIds {
            let newValue = infrastructuresSubject.value
                .filter {
                    !providerIds.contains($0.key)
                }
            infrastructuresSubject.send(newValue)
            return
        }
        infrastructuresSubject.send([:])
    }
}
