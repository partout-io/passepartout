// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonLibrary
import MiniFoundation
import Observation

@MainActor @Observable
public final class RegistryObservable {
    private let abi: AppABIRegistryProtocol

    public init(abi: AppABIRegistryProtocol) {
        self.abi = abi
    }

    public func newModule(ofType type: ModuleType) -> any ModuleBuilder {
        abi.newModule(ofType: type)
    }

    public func validate(_ builder: any ModuleBuilder) throws {
        try abi.validate(builder)
    }

    public func implementation(for builder: any ModuleBuilder) -> ModuleImplementation? {
        abi.implementation(for: builder.moduleHandler.id)
    }

    public func resolvedModule(_ module: ProviderModule) throws -> Module {
        try abi.resolvedModule(module)
    }
}
