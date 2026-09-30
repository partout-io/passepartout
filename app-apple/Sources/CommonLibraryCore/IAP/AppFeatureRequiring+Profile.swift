// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import Partout

extension Profile: AppFeatureRequiring {
    public var features: Set<ABI.AppFeature> {
        let builders: [any ModuleBuilder] = activeModules.compactMap { module in
            guard ![.Provider, .Custom].contains(module.moduleType) else { return nil }
            guard let builder = module.moduleBuilder() else {
                fatalError("Cannot produce ModuleBuilder from Module: \(module)")
            }
            return builder
        }
        return builders.features
    }
}

extension Array: AppFeatureRequiring where Element == any ModuleBuilder {
    public var features: Set<ABI.AppFeature> {
        let requirements = compactMap { builder in
            guard let requiring = builder as? AppFeatureRequiring else {
                fatalError("ModuleBuilder does not implement AppFeatureRequiring: \(builder)")
            }
            return requiring
        }
        return Set(requirements.flatMap(\.features))
    }
}
