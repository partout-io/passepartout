// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonLibrary
import Observation

@MainActor @Observable
public final class RegistryObservable {
    private enum Backend {
        case abi(AppABIRegistryProtocol)
        case registry(CodingRegistry)
    }

    private let backend: Backend

    public init(abi: AppABIRegistryProtocol) {
        backend = .abi(abi)
    }

    public init(registry: CodingRegistry) {
        backend = .registry(registry)
    }

    public func newModule(ofType type: ModuleType) -> any ModuleBuilder {
        switch backend {
        case .abi(let abi):
            return abi.newModule(ofType: type)
        case .registry(let registry):
            return registry.newModule(ofType: type)
        }
    }

    public func validate(_ builder: any ModuleBuilder) throws {
        switch backend {
        case .abi(let abi):
            try abi.validate(builder)
        case .registry(let registry):
            guard let impl = registry.implementation(for: builder.moduleType),
                  let validator = impl as? ModuleBuilderValidator else {
                return
            }
            try validator.validate(builder)
        }
    }

    public func implementation(for builder: any ModuleBuilder) -> ModuleImplementation? {
        switch backend {
        case .abi(let abi):
            return abi.implementation(for: builder.moduleType)
        case .registry(let registry):
            return registry.implementation(for: builder.moduleType)
        }
    }

    public func resolvedModule(_ module: ProviderModule) throws -> Module {
        switch backend {
        case .abi(let abi):
            return try abi.resolvedModule(module, in: nil)
        case .registry(let registry):
            return try registry.resolvedModule(module, in: nil)
        }
    }
}
