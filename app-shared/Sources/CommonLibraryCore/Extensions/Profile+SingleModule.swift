// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

extension Profile {
    public init(withName name: String, singleModule: Module) throws {
        let onDemandModule = OnDemandModule.Builder().build()
        var builder = Profile.Builder()
        builder.name = name
        builder.modules = [singleModule, onDemandModule]
        builder.activeModulesIds = Set(builder.modules.map(\.id))
        self = try builder.build()
    }
}
