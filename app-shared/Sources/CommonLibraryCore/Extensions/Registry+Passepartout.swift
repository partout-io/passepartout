// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#if !PSP_DYNLIB
import CommonProvidersCore
#endif
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
                try Self.resolvedModule($0, in: $1, with: mappedResolvers)
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
            pp_log_id(profile?.id, .core, .error, "Unable to resolve module: \(error)")
            throw error as? PartoutError ?? PartoutError(.Providers.corruptModule, error)
        }
    }
}
