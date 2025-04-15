//
//  CDProviderPreferencesRepositoryV3.swift
//  Passepartout
//
//  Created by Davide De Rosa on 12/5/24.
//  Copyright (c) 2025 Davide De Rosa. All rights reserved.
//
//  https://github.com/passepartoutvpn
//
//  This file is part of Passepartout.
//
//  Passepartout is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  Passepartout is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with Passepartout.  If not, see <http://www.gnu.org/licenses/>.
//

import AppData
import CommonLibrary
import CoreData
import Foundation

extension AppData {

    @MainActor
    public static func cdProviderPreferencesRepositoryV3(context: NSManagedObjectContext, providerId: ProviderID) throws -> ProviderPreferencesRepository {
        try CDProviderPreferencesRepositoryV3(context: context, providerId: providerId)
    }
}

private final class CDProviderPreferencesRepositoryV3: ProviderPreferencesRepository {
    private nonisolated let context: NSManagedObjectContext

    private let entity: CDProviderPreferencesV3

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
                pp_log(.app, .error, "Unable to load preferences for provider \(providerId): \(error)")
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
