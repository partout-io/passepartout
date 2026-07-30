// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonLibrary
import Observation

@MainActor @Observable
public final class RegistryObservable {
    private let registry: CodingRegistry

    public init(registry: CodingRegistry) {
        self.registry = registry
    }

    public func newModule(ofType type: ModuleType) -> any ModuleBuilder {
        registry.newModule(ofType: type)
    }

    public func validate(_ builder: any ModuleBuilder) throws {
        guard let impl = registry.implementation(for: builder.moduleType),
              let validator = impl as? ModuleBuilderValidator else {
            return
        }
        try validator.validate(builder)
    }

    public func implementation(for builder: any ModuleBuilder) -> ModuleImplementation? {
        registry.implementation(for: builder.moduleType)
    }

    public func resolvedModule(_ module: ProviderModule) throws -> Module {
        try registry.resolvedModule(module, in: nil)
    }
}
