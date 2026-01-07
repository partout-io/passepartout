// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonLibrary
import MiniFoundation
import Observation

@MainActor @Observable
public final class ModulesObservable {
    private let registry: Registry

    // For previews
    public init() {
        registry = Registry()
    }

    public init(abi: AppABIProtocol) {
        registry = abi.registry
    }

    public func newModule(ofType type: ModuleType) -> any ModuleBuilder {
        type.newModule(with: registry)
    }

    public func validate(_ builder: any ModuleBuilder) throws {
        guard let impl = registry.implementation(for: builder) as? ModuleBuilderValidator else {
            return
        }
        try impl.validate(builder)
    }

    public func implementation(for builder: any ModuleBuilder) -> ModuleImplementation? {
        registry.implementation(for: builder)
    }

    public func resolvedModule(_ module: ProviderModule) throws -> Module {
        try registry.resolvedModule(module, in: nil)
    }
}
