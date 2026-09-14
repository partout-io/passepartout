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

    @available(*, deprecated, message: "Legacy ModuleImplementation for WireGuard keygen, use ABI")
    public func newModule(ofType type: ModuleType) -> any ModuleBuilder {
        registry.newModule(ofType: type)
    }

    @available(*, deprecated, message: "Legacy ModuleImplementation, use ABI")
    public func validate(_ builder: any ModuleBuilder) throws {
        guard let impl = registry.implementation(for: builder.moduleType),
              let validator = impl as? ModuleBuilderValidator else {
            return
        }
        try validator.validate(builder)
    }

    @available(*, deprecated, message: "Legacy ModuleImplementation, use ABI")
    public func implementation(for builder: any ModuleBuilder) -> ModuleImplementation? {
        registry.implementation(for: builder.moduleType)
    }

    @available(*, deprecated, message: "Legacy Providers, will delete")
    public func resolvedModule(_ module: ProviderModule) throws -> Module {
        try registry.resolvedModule(module, in: nil)
    }
}
