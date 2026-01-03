// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonLibrary
import Partout

public struct EditableProfile: MutableProfileType {
    public let version: Int? = nil

    public var id: UUID

    public var name: String

    public var modules: [any ModuleBuilder]

    public var activeModulesIds: Set<UUID>

    public var behavior: ProfileBehavior?

    public var userInfo: JSON?

    public init(
        id: UUID = UUID(),
        name: String = "",
        modules: [any ModuleBuilder] = [],
        activeModulesIds: Set<UUID> = [],
        behavior: ProfileBehavior? = nil,
        userInfo: JSON? = nil
    ) {
        self.id = id
        self.name = name
        self.modules = modules
        self.activeModulesIds = activeModulesIds
        self.behavior = behavior
        self.userInfo = userInfo
    }

    public func builder() throws -> Profile.Builder {
        var builder = Profile.Builder(id: id)
        builder.modules = try modules.compactMap {
            do {
                return try $0.build()
            } catch {
                throw ABI.AppError.malformedModule($0, error: error)
            }
        }
        builder.activeModulesIds = activeModulesIds

        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        guard !trimmedName.isEmpty else {
            throw ABI.AppError.emptyProfileName
        }
        builder.name = trimmedName
        builder.behavior = behavior
        builder.userInfo = userInfo

        // some modules may require an active connection module (VPN)
        // for example, IP and HTTP Proxy modules require a VPN in NE
        if builder.activeConnectionModule == nil,
           let requiringConnection = builder.activeModules.first(where: \.requiresConnection) {
            throw ABI.AppError.moduleRequiresConnection(requiringConnection)
        }

        return builder
    }
}

extension Profile {
    public func editable() -> EditableProfile {
        EditableProfile(
            id: id,
            name: name,
            modules: modulesBuilders(),
            activeModulesIds: activeModulesIds,
            behavior: behavior,
            userInfo: userInfo
        )
    }

    public func modulesBuilders() -> [any ModuleBuilder] {
        modules.compactMap {
            $0.moduleBuilder()
        }
    }
}
