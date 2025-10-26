// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import Foundation

extension ProfileImporter {
    public func profile(withName name: String, singleModule module: Module) throws -> Profile {
        try Profile(withName: name, singleModule: module)
    }
}

private extension Profile {
    init(withName name: String, singleModule: Module) throws {
        let onDemandModule = OnDemandModule.Builder().build()
        var builder = Profile.Builder()
        builder.name = name
        builder.modules = [singleModule, onDemandModule]
        builder.activeModulesIds = Set(builder.modules.map(\.id))
        self = try builder.build()
    }
}
