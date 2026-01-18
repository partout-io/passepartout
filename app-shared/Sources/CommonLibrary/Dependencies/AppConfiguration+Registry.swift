// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import Partout

extension ABI.AppConfiguration {
    public func newRegistry(
        deviceId: String,
        configBlock: @escaping @Sendable () -> Set<ABI.ConfigFlag>
    ) -> Registry {
        let customHandlers: [ModuleHandler] = [
            ProviderModule.moduleHandler
        ]
        var allImplementations: [ModuleImplementation] = []
        var providerResolvers: [ProviderModuleResolver] = []
#if PSP_CROSS || canImport(PartoutOpenVPNConnection)
        allImplementations.append(
            OpenVPNImplementationBuilder(
                distributionTarget: distributionTarget,
                configBlock: configBlock
            ).build()
        )
#if !PSP_CROSS
        providerResolvers.append(OpenVPNProviderResolver())
#endif
#endif
#if PSP_CROSS || canImport(PartoutWireGuardConnection)
        allImplementations.append(
            WireGuardImplementationBuilder(
                configBlock: configBlock
            ).build()
        )
#if !PSP_CROSS
        providerResolvers.append(WireGuardProviderResolver(deviceId: deviceId))
#endif
#endif
        let mappedResolvers = providerResolvers
            .reduce(into: [:]) {
                $0[$1.moduleType] = $1
            }

        let registry = Registry(
            withKnown: true,
            customHandlers: customHandlers,
            allImplementations: allImplementations,
            resolvedModuleBlock: {
                do {
                    return try Registry.resolvedModule($0, in: $1, with: mappedResolvers)
                } catch {
                    pspLog($1?.id, .core, .error, "Unable to resolve module: \(error)")
                    throw error
                }
            }
        )
        registry.assertMissingImplementations()
        return registry
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

    func assertMissingImplementations() {
        ModuleType.allCases.forEach { moduleType in
            let builder = moduleType.newModule(with: self)
            do {
                // ModuleBuilder -> Module
                let module = try builder.build()

                // Module -> ModuleBuilder
                guard let moduleBuilder = module.moduleBuilder() else {
                    fatalError("\(moduleType): does not produce a ModuleBuilder")
                }

                // AppFeatureRequiring
                guard builder is any AppFeatureRequiring else {
                    fatalError("\(moduleType): #1 is not AppFeatureRequiring")
                }
                guard moduleBuilder is any AppFeatureRequiring else {
                    fatalError("\(moduleType): #2 is not AppFeatureRequiring")
                }
            } catch {
                switch (error as? PartoutError)?.code {
                case .incompleteModule, .WireGuard.emptyPeers:
                    return
                default:
                    fatalError("\(moduleType): empty module is not buildable: \(error)")
                }
            }
        }
    }
}
