// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#if !PSP_MONOLITH
import CommonProvidersCore
#endif
import Partout

public typealias APIRepository = APIRepositoryReader & APIRepositoryWriter

public protocol APIRepositoryReader: Sendable {
    var indexStream: AsyncStream<[Provider]> { get }

    var cacheStream: AsyncStream<[ProviderID: ProviderCache]> { get }

    func presets(for server: ProviderServer, moduleType: ModuleType) async throws -> [ProviderPreset]

    func providerRepository(for providerId: ProviderID, sort: @escaping ProviderServerParameters.Sorter) -> ProviderRepository
}

public protocol APIRepositoryWriter: Sendable {
    func store(_ index: [Provider]) async throws

    func store(_ infrastructure: ProviderInfrastructure, for providerId: ProviderID) async throws

    func resetCache(for providerIds: [ProviderID]?) async
}

extension APIRepositoryWriter {
    public func resetCache() async {
        await resetCache(for: nil)
    }
}
