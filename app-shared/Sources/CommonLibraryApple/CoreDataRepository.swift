// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#if !PSP_DYNLIB
import CommonLibraryCore
#endif
@preconcurrency import CoreData
import Foundation
import Partout

public protocol CoreDataUniqueEntity: NSManagedObject, UniqueEntity {
    // Core Data entity must have a unique "uuid" field
}

public enum CoreDataResultAction {
    case ignore

    case discard

    case halt
}

public actor CoreDataRepository<CD, T>: NSObject, Repository, NSFetchedResultsControllerDelegate
        where CD: CoreDataUniqueEntity, T: UniqueEntity {

    private let entityName: String

    private nonisolated let context: NSManagedObjectContext

    private let observingResults: Bool

    private let beforeFetch: ((NSFetchRequest<CD>) -> Void)?

    private nonisolated let fromMapper: @Sendable (CD) throws -> T?

    private nonisolated let toMapper: @Sendable (T, NSManagedObjectContext) throws -> CD

    private nonisolated let onResultError: (@Sendable (Error) -> CoreDataResultAction)?

    private nonisolated let entitiesSubject: CurrentValueStream<EntitiesResult<T>>

    private var resultsController: NSFetchedResultsController<CD>?

    public init(
        context: NSManagedObjectContext,
        observingResults: Bool,
        beforeFetch: (@Sendable (NSFetchRequest<CD>) -> Void)? = nil,
        fromMapper: @escaping @Sendable (CD) throws -> T?,
        toMapper: @escaping @Sendable (T, NSManagedObjectContext) throws -> CD,
        onResultError: (@Sendable (Error) -> CoreDataResultAction)? = nil
    ) {
        guard let entityName = CD.entity().name else {
            fatalError("Unable to find entity name for \(CD.self)")
        }

        self.entityName = entityName
        self.context = context
        self.observingResults = observingResults
        self.beforeFetch = beforeFetch
        self.fromMapper = fromMapper
        self.toMapper = toMapper
        self.onResultError = onResultError
        entitiesSubject = CurrentValueStream(EntitiesResult())
    }

    public nonisolated var entitiesPublisher: AsyncStream<EntitiesResult<T>> {
        entitiesSubject.subscribe()
    }

    public func filter(byFormat format: String, arguments: [Sendable]?) async throws {
        try await filter(byPredicate: NSPredicate(format: format, argumentArray: arguments))
    }

    public func resetFilter() async throws {
        try await filter(byPredicate: nil)
    }

    public func fetchAllEntities() async throws -> [T] {
        try await filter(byPredicate: nil)
    }

    public func saveEntities(_ entities: [T]) async throws {
        try await context.perform { [weak self] in
            guard let self else {
                return
            }
            do {
                let request = newFetchRequest()
                let existingIds = entities.compactMap(\.uuid)
                request.predicate = NSPredicate(
                    format: "any uuid in %@",
                    existingIds
                )
                let existing = try context.fetch(request)
                existing.forEach(context.delete)
                for entity in entities {
                    _ = try self.toMapper(entity, context)
                }
                try context.save()
            } catch {
                context.rollback()
                throw error
            }
        }
    }

    public func removeEntities(withIds ids: [UUID]?) async throws {
        try await context.perform { [weak self] in
            guard let self else {
                return
            }
            let request = newFetchRequest()
            if let ids {
                request.predicate = NSPredicate(
                    format: "any uuid in %@",
                    ids
                )
            }
            do {
                let existing = try context.fetch(request)
                existing.forEach(context.delete)
                try context.save()
            } catch {
                context.rollback()
                throw error
            }
        }
    }

    // MARK: NSFetchedResultsControllerDelegate

    // XXX: triggers on entity insert/update/delete and reloads/remaps ALL into entitiesSubject
    public nonisolated func controllerDidChangeContent(_ controller: NSFetchedResultsController<any NSFetchRequestResult>) {
        guard observingResults else {
            return
        }
        guard let cdController = controller as? NSFetchedResultsController<CD> else {
            fatalError("Unable to upcast results to \(CD.self)")
        }
        Task.detached { [weak self] in
            await self?.sendResults(from: cdController)
        }
    }
}

private extension CoreDataRepository {
    enum ResultError: Error {
        case mapping(Error)
    }

    nonisolated func newFetchRequest() -> NSFetchRequest<CD> {
        NSFetchRequest(entityName: entityName)
    }

    @discardableResult
    func filter(byPredicate predicate: NSPredicate?) async throws -> [T] {
        let request = newFetchRequest()
        request.predicate = predicate
        beforeFetch?(request)

        let newController = NSFetchedResultsController(
            fetchRequest: request,
            managedObjectContext: context,
            sectionNameKeyPath: nil,
            cacheName: nil
        )
        newController.delegate = self
        resultsController = newController

        return try await context.perform {
            try newController.performFetch()
            return self.unsafeSendResults(from: newController)
        }
    }

    @discardableResult
    func sendResults(from controller: NSFetchedResultsController<CD>) async -> [T] {
        await context.perform {
            self.unsafeSendResults(from: controller)
        }
    }

    @discardableResult
    nonisolated func unsafeSendResults(from controller: NSFetchedResultsController<CD>) -> [T] {
        guard var cdEntities = controller.fetchedObjects else {
            return []
        }

        var entitiesToDelete: [CD] = []

        // strip duplicates by sort order (first entry wins)
        var knownUUIDs = Set<UUID>()
        cdEntities.forEach {
            guard let uuid = $0.uuid else {
                return
            }
            guard !knownUUIDs.contains(uuid) else {
                NSLog("Strip duplicate \(String(describing: CD.self)) with UUID \(uuid)")
                entitiesToDelete.append($0)
                return
            }
            knownUUIDs.insert(uuid)
        }

        do {
            cdEntities.removeAll {
                entitiesToDelete.contains($0)
            }
            let entities = try cdEntities.compactMap {
                do {
                    return try fromMapper($0)
                } catch {
                    switch onResultError?(error) {
                    case .discard:
                        entitiesToDelete.append($0)

                    case .halt:
                        throw ResultError.mapping(error)

                    default:
                        break
                    }
                    return nil
                }
            }
            if !entitiesToDelete.isEmpty {
                do {
                    entitiesToDelete.forEach(context.delete)
                    try context.save()
                } catch {
                    NSLog("Unable to delete Core Data entities: \(error)")
                    context.rollback()
                }
            }

            let result = EntitiesResult(entities, isFiltering: controller.fetchRequest.predicate != nil)
            entitiesSubject.send(result)
            return result.entities
        } catch {
            NSLog("Unable to send Core Data entities: \(error)")
            return []
        }
    }
}
