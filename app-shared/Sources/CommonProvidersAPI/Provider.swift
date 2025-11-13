// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonProvidersCore
import Foundation
import Partout

public struct Provider: Identifiable, Hashable, CustomStringConvertible, Sendable {
    public let id: ProviderID

    public let description: String

    public let metadata: [ModuleType: Metadata]

    public init(_ id: String, description: String, moduleTypes: [Module.Type]) {
        self.init(id, description: description, metadata: moduleTypes.reduce(into: [:]) {
            $0[$1.moduleHandler.id] = Metadata()
        })
    }

    public init(_ id: String, description: String, handlers: [ModuleHandler]) {
        self.init(id, description: description, metadata: handlers.reduce(into: [:]) {
            $0[$1.id] = Metadata()
        })
    }

    public init(_ id: String, description: String, metadata: [ModuleType: Metadata] = [:]) {
        self.id = ProviderID(rawValue: id)
        self.description = description
        self.metadata = metadata
    }
}

extension Provider {
    public func supports(_ moduleType: ModuleType) -> Bool {
        metadata.keys.contains(moduleType)
    }

    public func supports<M>(_ moduleType: M.Type) -> Bool where M: Module {
        metadata.keys.contains(moduleType.moduleHandler.id)
    }

    public func metadata<M>(for moduleType: M.Type) -> Metadata? where M: Module {
        metadata[moduleType.moduleHandler.id]
    }
}
