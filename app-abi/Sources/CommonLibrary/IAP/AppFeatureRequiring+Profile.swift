// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

extension Profile: ABI.AppFeatureRequiring {
    public var features: Set<ABI.AppFeature> {
        let builders = activeModules.compactMap { module in
            guard let builder = module.moduleBuilder() else {
                fatalError("Cannot produce ModuleBuilder from Module: \(module)")
            }
            return builder
        }
        return builders.features
    }
}

extension Array: ABI.AppFeatureRequiring where Element == any ModuleBuilder {
    public var features: Set<ABI.AppFeature> {
        let requirements = compactMap { builder in
            guard let requiring = builder as? ABI.AppFeatureRequiring else {
                fatalError("ModuleBuilder does not implement AppFeatureRequiring: \(builder)")
            }
            return requiring
        }
        return Set(requirements.flatMap(\.features))
    }
}
