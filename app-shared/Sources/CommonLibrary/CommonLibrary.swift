// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#if canImport(CommonLibraryWeb)
@_exported import CommonLibraryWeb
#endif
@_exported import CommonProviders
@_exported import Partout

public enum CommonLibrary {
    public static func assertMissingImplementations(with registry: Registry) {
        ModuleType.allCases.forEach { moduleType in
            let builder = moduleType.newModule(with: registry)
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
