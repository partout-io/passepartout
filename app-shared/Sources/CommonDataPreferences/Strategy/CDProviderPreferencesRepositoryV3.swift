// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CoreData

extension CommonData {

    @MainActor
    public static func cdProviderPreferencesRepositoryV3(context: NSManagedObjectContext, providerId: ProviderID) throws -> ProviderPreferencesRepository {
        try CDProviderPreferencesRepositoryV3(context: context, providerId: providerId)
    }
}

private final class CDProviderPreferencesRepositoryV3: ProviderPreferencesRepository {
    private nonisolated let context: NSManagedObjectContext

    private nonisolated(unsafe) let entity: CDProviderPreferencesV3

    init(context: NSManagedObjectContext, providerId: ProviderID) throws {
        self.context = context

        entity = try context.performAndWait {
            let request = CDProviderPreferencesV3.fetchRequest()
            request.predicate = NSPredicate(format: "providerId == %@", providerId.rawValue)
            request.sortDescriptors = [.init(key: "lastUpdate", ascending: false)]
            do {
                let entities = try request.execute()

                // dedup by lastUpdate
                entities.enumerated().forEach {
                    guard $0.offset > 0 else {
                        return
                    }
                    $0.element.favoriteServers?.forEach(context.delete(_:))
                    context.delete($0.element)
                }

                let entity = entities.first ?? CDProviderPreferencesV3(context: context)
                entity.providerId = providerId.rawValue
                entity.lastUpdate = Date()

                // migrate favorite server ids
                if let favoriteServerIds = entity.favoriteServerIds {
                    let mapper = CoreDataMapper(context: context)
                    let ids = try? JSONDecoder().decode(Set<String>.self, from: favoriteServerIds)
                    var favoriteServers: Set<CDFavoriteServer> = []
                    ids?.forEach {
                        favoriteServers.insert(mapper.cdFavoriteServer(from: $0))
                    }
                    entity.favoriteServers = favoriteServers
                    entity.favoriteServerIds = nil
                }

                return entity
            } catch {
                pp_log_g(.App.core, .error, "Unable to load preferences for provider \(providerId): \(error)")
                throw error
            }
        }
    }

    func isFavoriteServer(_ serverId: String) -> Bool {
        context.performAndWait {
            entity.favoriteServers?.contains {
                $0.serverId == serverId
            } ?? false
        }
    }

    func addFavoriteServer(_ serverId: String) {
        context.performAndWait {
            guard entity.favoriteServers?.contains(where: {
                $0.serverId == serverId
            }) != true else {
                return
            }
            let mapper = CoreDataMapper(context: context)
            let cdFavorite = mapper.cdFavoriteServer(from: serverId)
            cdFavorite.providerPreferences = entity
            entity.favoriteServers?.insert(cdFavorite)
        }
    }

    func removeFavoriteServer(_ serverId: String) {
        context.performAndWait {
            guard let found = entity.favoriteServers?.first(where: {
                $0.serverId == serverId
            }) else {
                return
            }
            entity.favoriteServers?.remove(found)
            context.delete(found)
        }
    }

    func save() throws {
        try context.performAndWait {
            guard context.hasChanges else {
                return
            }
            do {
                try context.save()
            } catch {
                context.rollback()
                throw error
            }
        }
    }
}
