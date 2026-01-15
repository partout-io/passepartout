// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import Partout

extension Registry {
    public convenience init(
        providerResolvers: [ProviderModuleResolver],
        allImplementations: [ModuleImplementation]
    ) {
        let customHandlers: [ModuleHandler] = [
            ProviderModule.moduleHandler
        ]
        let mappedResolvers = providerResolvers
            .reduce(into: [:]) {
                $0[$1.moduleType] = $1
            }

        self.init(
            withKnown: true,
            customHandlers: customHandlers,
            allImplementations: allImplementations,
            resolvedModuleBlock: {
                do {
                    return try Self.resolvedModule($0, in: $1, with: mappedResolvers)
                } catch {
                    pspLog($1?.id, .core, .error, "Unable to resolve module: \(error)")
                    throw error
                }
            }
        )
    }
}

private extension Registry {
    @Sendable
    static func resolvedModule(
        _ module: Module,
        in profile: Profile?,
        with resolvers: [ModuleType: ProviderModuleResolver]
    ) throws -> Module {
        do {
            if let profile {
                profile.assertSingleActiveProviderModule()
                guard profile.isActiveModule(withId: module.id) else {
                    return module
                }
            }
            guard let providerModule = module as? ProviderModule else {
                return module
            }
            guard let resolver = resolvers[providerModule.providerModuleType] else {
                return module
            }
            return try resolver.resolved(from: providerModule)
        } catch {
            throw error as? PartoutError ?? PartoutError(.Providers.corruptModule, error)
        }
    }
}
