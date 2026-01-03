// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CoreData

final class CDProviderRepositoryV3: ProviderRepository {
    private nonisolated let context: NSManagedObjectContext

    let providerId: ProviderID

    init(context: NSManagedObjectContext, providerId: ProviderID) {
        self.context = context
        self.providerId = providerId
    }

    func availableOptions(for moduleType: ModuleType) async throws -> ProviderFilterOptions {
        try await context.perform {
            let mapper = DomainMapper()

            let serversRequest = NSFetchRequest<NSDictionary>(entityName: "CDProviderServerV3")
            serversRequest.predicate = self.providerId.predicate
            serversRequest.resultType = .dictionaryResultType
            serversRequest.returnsDistinctResults = true
            serversRequest.propertiesToFetch = [
                "categoryName",
                "countryCode"
            ]
            let serversResults = try serversRequest.execute()

            var countriesByCategoryName: [String: Set<String>] = [:]
            var countryCodes: Set<String> = []
            serversResults.forEach {
                guard let categoryName = $0.object(forKey: "categoryName") as? String,
                      let countryCode = $0.object(forKey: "countryCode") as? String else {
                    return
                }
                var codes: Set<String> = countriesByCategoryName[categoryName] ?? []
                codes.insert(countryCode)
                countriesByCategoryName[categoryName] = codes
                countryCodes.insert(countryCode)
            }

            let presetsRequest = CDProviderPresetV3.fetchRequest()
            presetsRequest.predicate = NSPredicate(
                format: "providerId == %@ AND moduleType == %@",
                self.providerId.rawValue,
                moduleType.rawValue
            )
            let presetsResults = try presetsRequest.execute()

            return ProviderFilterOptions(
                countriesByCategoryName: countriesByCategoryName,
                countryCodes: Set(countryCodes),
                presets: Set(try presetsResults.compactMap {
                    try mapper.preset(from: $0)
                })
            )
        }
    }

    func filteredServers(with parameters: ProviderServerParameters?) async throws -> [ProviderServer] {
        try await context.perform {
            let request = CDProviderServerV3.fetchRequest()
            request.sortDescriptors = parameters?.sorting.map(\.sortDescriptor)
            request.predicate = parameters?.filters.predicate(for: self.providerId)
            let results = try request.execute()
            let mapper = DomainMapper()
            return try results.compactMap(mapper.server(from:))
        }
    }
}
