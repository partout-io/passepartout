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
        abi.registryNewModule(ofType: type)
    }

    public func validate(_ builder: any ModuleBuilder) throws {
        guard let impl = abi.registryImplementation(for: builder) as? ModuleBuilderValidator else {
            return
        }
        try impl.validate(builder)
    }

    public func implementation(for builder: any ModuleBuilder) -> ModuleImplementation? {
        abi.registryImplementation(for: builder)
    }

    public func resolvedModule(_ module: ProviderModule) throws -> Module {
        try abi.registryResolvedModule(module)
    }

    public func importedProfile(from input: ABI.ProfileImporterInput, passphrase: String?) throws -> Profile {
        try abi.registryImportedProfile(from: input, passphrase: passphrase)
    }
}
