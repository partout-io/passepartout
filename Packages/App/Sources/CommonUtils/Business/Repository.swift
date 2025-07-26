// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import Combine
import Foundation

public protocol UniqueEntity {
    var uuid: UUID? { get }
}

public struct EntitiesResult<E> where E: UniqueEntity {
    public let entities: [E]

    public let isFiltering: Bool

    public init() {
        self.init([], isFiltering: false)
    }

    public init(_ entities: [E], isFiltering: Bool) {
        self.entities = entities
        self.isFiltering = isFiltering
    }
}

public protocol Repository {
    associatedtype Entity: UniqueEntity

    var entitiesPublisher: AnyPublisher<EntitiesResult<Entity>, Never> { get }

    func filter(byFormat format: String, arguments: [Any]?) async throws

    func resetFilter() async throws

    func saveEntities(_ entities: [Entity]) async throws

    func removeEntities(withIds ids: [UUID]?) async throws
}
