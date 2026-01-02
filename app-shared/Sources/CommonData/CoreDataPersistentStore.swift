// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CoreData

public final class CoreDataPersistentStore: Sendable {
    private let logger: AppLogger?

    private let container: NSPersistentContainer

    public convenience init(
        logger: AppLogger? = nil,
        containerName: String,
        baseURL: URL? = nil,
        model: NSManagedObjectModel,
        cloudKitIdentifier: String?,
        author: String?
    ) {
        let container: NSPersistentContainer
        if let cloudKitIdentifier {
            container = NSPersistentCloudKitContainer(name: containerName, managedObjectModel: model)
            logger?.log(.core, .debug, "Set up CloudKit container (\(cloudKitIdentifier)): \(containerName)")
        } else {
            container = NSPersistentContainer(name: containerName, managedObjectModel: model)
            logger?.log(.core, .debug, "Set up local container: \(containerName)")
        }
        if let baseURL {
            let url = baseURL.appending(component: "\(containerName).sqlite")
            container.persistentStoreDescriptions = [.init(url: url)]
        }
        self.init(
            logger: logger,
            container: container,
            cloudKitIdentifier: cloudKitIdentifier,
            author: author
        )
    }

    private init(
        logger: AppLogger?,
        container: NSPersistentContainer,
        cloudKitIdentifier: String?,
        author: String?
    ) {
        self.logger = logger
        self.container = container

        guard let desc = container.persistentStoreDescriptions.first else {
            fatalError("Unable to read persistent store description")
        }
        logger?.log(.core, .debug, "Container description: \(desc)")

        // optional container identifier for CloudKit, first in entitlements otherwise
        if let cloudKitIdentifier {
            desc.cloudKitContainerOptions = .init(containerIdentifier: cloudKitIdentifier)
        }

        // set this even for local container, to avoid readonly mode in case
        // container was formerly created with CloudKit option
        desc.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)

        // migrate automatically
        desc.setOption(true as NSNumber, forKey: NSMigratePersistentStoresAutomaticallyOption)
        desc.setOption(true as NSNumber, forKey: NSInferMappingModelAutomaticallyOption)

        // report remote notifications (do this BEFORE loadPersistentStores)
        //
        // https://stackoverflow.com/a/69507329/784615
//        desc.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
        container.loadPersistentStores {
            if let error = $1 {
                fatalError("Unable to load persistent store: \(error)")
            }
        }
        container.viewContext.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
        container.viewContext.automaticallyMergesChangesFromParent = true

        if let author {
            logger?.log(.core, .debug, "Setting transaction author: \(author)")
            container.viewContext.transactionAuthor = author
        }
    }
}

extension CoreDataPersistentStore {
    public var context: NSManagedObjectContext {
        container.viewContext
    }

    public func backgroundContext() -> NSManagedObjectContext {
        container.newBackgroundContext()
    }
}

// MARK: Development

extension CoreDataPersistentStore {
    public var containerURLs: [URL]? {
        guard let url = container.persistentStoreDescriptions.first?.url else {
            return nil
        }
        return [
            url,
            url.deletingPathExtension().appendingPathExtension("sqlite-shm"),
            url.deletingPathExtension().appendingPathExtension("sqlite-wal")
        ]
    }

    public func truncate() {
        let coordinator = container.persistentStoreCoordinator
        container.persistentStoreDescriptions.forEach {
            do {
                try $0.url.map {
                    try coordinator.destroyPersistentStore(at: $0, ofType: NSSQLiteStoreType)
                    try coordinator.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: $0, options: nil)
                }
            } catch {
                logger?.log(.core, .error, "Unable to truncate persistent store: \(error)")
            }
        }
    }
}
