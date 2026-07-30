// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CoreData
import Partout

extension CommonData {

    @MainActor
    public static func cdModulePreferencesRepositoryV3(
        context: NSManagedObjectContext,
        moduleId: UniqueID
    ) throws -> ModulePreferencesRepository {
        try CDModulePreferencesRepositoryV3(context: context, moduleId: moduleId)
    }
}

private final class CDModulePreferencesRepositoryV3: ModulePreferencesRepository {
    private nonisolated let context: NSManagedObjectContext

    private nonisolated(unsafe) let entity: CDModulePreferencesV3

    init(context: NSManagedObjectContext, moduleId: UniqueID) throws {
        self.context = context

        entity = try context.performAndWait {
            let request = CDModulePreferencesV3.fetchRequest()
            request.predicate = NSPredicate(format: "moduleId == %@", moduleId.uuidString)
            request.sortDescriptors = [.init(key: "lastUpdate", ascending: false)]
            let entities = try request.execute()

            // Dedup by lastUpdate
            entities.enumerated().forEach {
                guard $0.offset > 0 else {
                    return
                }
                $0.element.excludedEndpoints?.forEach(context.delete(_:))
                context.delete($0.element)
            }

            let entity = entities.first ?? CDModulePreferencesV3(context: context)
            entity.moduleId = moduleId
            entity.lastUpdate = Date()
            return entity
        }
    }

    func isExcludedEndpoint(_ endpoint: ExtendedEndpoint) -> Bool {
        context.performAndWait {
            entity.excludedEndpoints?.contains {
                $0.endpoint == endpoint.rawValue
            } ?? false
        }
    }

    func addExcludedEndpoint(_ endpoint: ExtendedEndpoint) {
        context.performAndWait {
            guard entity.excludedEndpoints?.contains(where: {
                $0.endpoint == endpoint.rawValue
            }) != true else {
                return
            }
            let mapper = CoreDataMapper(context: context)
            let cdEndpoint = mapper.cdExcludedEndpoint(from: endpoint)
            cdEndpoint.modulePreferences = entity
            entity.excludedEndpoints?.insert(cdEndpoint)
        }
    }

    func removeExcludedEndpoint(_ endpoint: ExtendedEndpoint) {
        context.performAndWait {
            guard let found = entity.excludedEndpoints?.first(where: {
                $0.endpoint == endpoint.rawValue
            }) else {
                return
            }
            entity.excludedEndpoints?.remove(found)
            context.delete(found)
        }
    }

    func erase() {
        context.performAndWait {
            entity.excludedEndpoints?.forEach(context.delete)
            context.delete(entity)
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
