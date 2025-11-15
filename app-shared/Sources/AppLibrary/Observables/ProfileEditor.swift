// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import Combine
import CommonLibrary
import Foundation
import Partout

@MainActor
public final class ProfileEditor: ObservableObject {

    @Published
    var editableProfile: ABI.EditableProfile

    @Published
    public var isShared: Bool

    var removedModules: [UUID: any ModuleBuilder]

    public convenience init() {
        self.init(modules: [])
    }

    // for testing/previews
    public init(profile: Profile) {
        editableProfile = profile.editable()
        isShared = false
        removedModules = [:]
    }

    // for testing/previews
    public init(modules: [any ModuleBuilder]) {
        editableProfile = ABI.EditableProfile(
            modules: modules,
            activeModulesIds: Set(modules.map(\.id))
        )
        isShared = false
        removedModules = [:]
    }
}

// MARK: - Types

extension ProfileEditor {
    public var moduleTypes: [ModuleType] {
        editableProfile.modules
            .map(\.moduleType)
    }

    public func availableModuleTypes(forTarget target: ABI.DistributionTarget) -> [ModuleType] {
        let types: [ModuleType]
        if target.supportsPaidFeatures {
            types = ModuleType.allCases
        } else {
            types = [.onDemand, .openVPN, .wireGuard]
        }
        return types
            .filter {
                !moduleTypes.contains($0)
            }
    }
}

// MARK: - Editing

extension ProfileEditor {
    public var profile: ABI.EditableProfile {
        get {
            editableProfile
        }
        set {
            editableProfile = newValue
        }
    }

    public var keepsAliveOnSleep: Bool {
        get {
            !editableProfile.disconnectsOnSleep
        }
        set {
            var behavior = editableProfile.behavior ?? ProfileBehavior()
            behavior.disconnectsOnSleep = !newValue
            editableProfile.behavior = behavior
        }
    }

    public var enforceTunnel: Bool {
        get {
            editableProfile.includesAllNetworks
        }
        set {
            var behavior = editableProfile.behavior ?? ProfileBehavior()
            behavior.includesAllNetworks = newValue
            editableProfile.behavior = behavior
        }
    }

    public var isAvailableForTV: Bool {
        get {
            editableProfile.attributes.isAvailableForTV == true
        }
        set {
            editableProfile.attributes.isAvailableForTV = newValue
        }
    }
}

extension ProfileEditor {
    public var modules: [any ModuleBuilder] {
        editableProfile.modules
    }

    public var activeModules: [any ModuleBuilder] {
        editableProfile.modules.filter {
            isActiveModule(withId: $0.id)
        }
    }

    public func module(withId moduleId: UUID) -> (any ModuleBuilder)? {
        editableProfile.modules.first {
            $0.id == moduleId
        } ?? removedModules[moduleId]
    }

    public func isActiveModule(withId moduleId: UUID) -> Bool {
        editableProfile.isActiveModule(withId: moduleId)
    }

    public func toggleModule(withId moduleId: UUID) {
        guard let existingModule = module(withId: moduleId) else {
            return
        }
        if isActiveModule(withId: moduleId) {
            editableProfile.activeModulesIds.remove(moduleId)
        } else {
            activateModule(existingModule)
        }
    }

    public func moveModules(from offsets: IndexSet, to newOffset: Int) {
        editableProfile.modules.move(fromOffsets: offsets, toOffset: newOffset)
    }

    public func removeModules(at offsets: IndexSet) {
        offsets.forEach {
            let module = editableProfile.modules[$0]
            removedModules[module.id] = module
            editableProfile.modules.remove(at: $0)
        }
    }

    public func removeModule(withId moduleId: UUID) {
        guard let index = editableProfile.modules.firstIndex(where: { $0.id == moduleId }) else {
            return
        }
        let module = editableProfile.modules[index]
        removedModules[module.id] = module
        editableProfile.modules.remove(at: index)
    }

    public func saveModule(_ module: any ModuleBuilder, activating: Bool) {
        if let index = editableProfile.modules.firstIndex(where: { $0.id == module.id }) {
            editableProfile.modules[index] = module
        } else {
            editableProfile.modules.append(module)
        }
        if activating {
            activateModule(module)
        }
    }

    public func discard() {
    }
}

private extension ProfileEditor {
    func activateModule(_ module: any ModuleBuilder) {
        editableProfile.activeModulesIds.insert(module.id)
    }
}

// MARK: - Building

extension ProfileEditor {
    public func buildAndUpdate() throws -> Profile {
        try buildAndUpdate(with: nil)
    }

    public func buildAndUpdate(with registry: Registry?) throws -> Profile {
        try build(with: registry, updating: true)
    }

    public func build(with registry: Registry?, updating: Bool) throws -> Profile {

        // Add this check in the app, the library does not enforce it
        guard !editableProfile.activeModulesIds.isEmpty else {
            throw PartoutError(.noActiveModules)
        }

        // Validate builders if implementation supports it
        try editableProfile.modules.forEach {
            guard let impl = registry?.implementation(for: $0) as? ModuleBuilderValidator else {
                return
            }
            do {
                try impl.validate($0)
            } catch {
                throw ABI.AppError.malformedModule($0, error: error)
            }
        }

        let builder = try editableProfile.builder()
        let profile = try builder.build()

        // Update local view
        if updating {
            editableProfile.modules = profile.modulesBuilders()
        }

        return profile
    }
}

// MARK: - Testing

extension ProfileEditor {
    var activeModulesIds: Set<UUID> {
        editableProfile.activeModulesIds
    }
}
