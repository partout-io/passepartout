// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonLibrary

public struct EditableProfile: MutableProfileType {
    public let version: Int? = nil

    // Modules without an editor still belong to the profile and must survive saves.
    fileprivate var retainedModules: [(index: Int, module: Module)] = []

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
                throw ABI.AppError.malformedModule($0, reason: error)
            }
        }
        for retained in retainedModules {
            builder.modules.insert(retained.module, at: min(retained.index, builder.modules.count))
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
        if !builder.hasConnection,
           let requiringConnection = builder.activeModules.first(where: \.requiresConnection) {
            throw ABI.AppError.moduleRequiresConnection(requiringConnection)
        }

        return builder
    }
}

private extension Profile.Builder {
    var hasConnection: Bool {
        modules.contains {
            activeModulesIds.contains($0.id) && ($0.moduleType.isConnection || $0.isLegacyProviderConnection)
        }
    }
}

extension Profile {
    public func editable() -> EditableProfile {
        var editable = EditableProfile(
            id: id,
            name: name,
            modules: modulesBuilders(),
            activeModulesIds: activeModulesIds,
            behavior: behavior,
            userInfo: userInfo
        )
        editable.retainedModules = modules.enumerated().compactMap { index, module in
            module.moduleBuilder() == nil ? (index, module) : nil
        }
        return editable
    }

    public func modulesBuilders() -> [any ModuleBuilder] {
        modules.compactMap {
            $0.moduleBuilder()
        }
    }
}
