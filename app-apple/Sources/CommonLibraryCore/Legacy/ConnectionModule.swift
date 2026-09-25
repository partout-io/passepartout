// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import Partout

public protocol ConnectionModule: Module {
}

extension ConnectionModule {
    public var buildsConnection: Bool {
        true
    }

    // allow one active ConnectionModule at most
    public func checkCompatible(with otherModule: Module, activeIds: Set<UniqueID>) throws {
        precondition(otherModule.id != id)
        if !activeIds.contains(id) || !activeIds.contains(otherModule.id) {
            return
        }
        guard !otherModule.buildsConnection else {
            throw PartoutError(.incompatibleModules, [self, otherModule])
        }
    }
}

extension ProfileType where GenericModuleType == Module {
    public var activeConnectionModule: ConnectionModule? {
        activeModules.first(ofType: ConnectionModule.self)
    }
}
