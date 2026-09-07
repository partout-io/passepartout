// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import Partout

@available(*, deprecated)
public final class Registry: Sendable {
    public typealias ResolvedModuleBlock = @Sendable (Module, Profile?) throws -> Module?

    // Handlers are only needed for legacy decoding. These
    // can be removed after switching to TaggedModule.
    private let allHandlers: [ModuleType: ModuleHandler]

    private let allImplementations: [ModuleType: ModuleImplementation]

    private let resolvedModuleBlock: ResolvedModuleBlock?

    public init(
        allHandlers: [ModuleHandler],
        allImplementations: [ModuleImplementation] = [],
        resolvedModuleBlock: ResolvedModuleBlock? = nil
    ) {
        self.allHandlers = allHandlers
            .reduce(into: [:]) {
                $0[$1.id] = $1
            }
        self.allImplementations = allImplementations
            .reduce(into: [:]) {
                $0[$1.moduleType] = $1
            }
        self.resolvedModuleBlock = resolvedModuleBlock
    }
}

// MARK: - ConnectionFactory

extension Registry: ConnectionFactory {
    public func connection(for connectionModule: ConnectionModule, parameters: ConnectionParameters) throws -> Connection {
        let impl = implementation(for: connectionModule.moduleType)
        return try connectionModule.newConnection(with: impl, parameters: parameters)
    }
}

// MARK: ModuleRegistry

extension Registry: ModuleRegistry {
    public func implementation(for moduleBuilder: any ModuleBuilder) -> ModuleImplementation? {
        allImplementations[moduleBuilder.moduleType]
    }

    public func implementation(for moduleType: ModuleType) -> ModuleImplementation? {
        allImplementations[moduleType]
    }
}

// MARK: ModuleImporter

extension Registry: ModuleImporter {
    public nonisolated func module(fromContents contents: String, object: Any?) throws -> Module {
        var wasHandled = false
        var errors: [Error] = []
        for impl in allImplementations.values {
            guard let importer = impl as? ModuleImporter else {
                continue
            }
            wasHandled = true
            do {
                return try importer.module(fromContents: contents, object: object)
            } catch {
                // URL content is not recognized by this importer, skip to next importer
                if error.partoutErrorCode != .unknownImportedModule {
                    errors.append(error)
                }
                continue
            }
        }
        if let error = errors.first {
            throw PartoutError(error)
        }
        guard wasHandled else {
            throw PartoutError(.unknownImportedModule)
        }
        throw PartoutError(.parsing)
    }
}

// MARK: Resolver

extension Registry: Resolver {
    public func resolvedProfile(_ profile: Profile) throws -> Profile {
        var copy = profile.builder()
        copy.modules = try copy.modules.map {
            try resolvedModule($0, in: profile)
        }
        return try copy.build()
    }

    public func resolvedModule(_ module: Module, in profile: Profile?) throws -> Module {
        try resolvedModuleBlock?(module, profile) ?? module
    }
}

// MARK: - Helpers

@available(*, deprecated, message: "ModuleHandler is deprecated")
extension Registry {
    public func handler(withId id: ModuleType) -> ModuleHandler? {
        allHandlers[id]
    }

    public func isRegistered(_ handler: ModuleHandler) -> Bool {
        allHandlers[handler.id] != nil
    }
}
