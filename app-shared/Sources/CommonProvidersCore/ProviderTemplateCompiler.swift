// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import Partout

public protocol ProviderTemplateCompiler {
    associatedtype CompiledModule: Module

    associatedtype Options: ProviderOptions

    associatedtype UserInfo

    func compiled(
        _ ctx: PartoutLoggerContext,
        moduleId: UniqueID,
        entity: ProviderEntity,
        options: Options?,
        userInfo: UserInfo?
    ) throws -> CompiledModule
}

extension ProviderTemplateCompiler {
    public var moduleType: ModuleType {
        CompiledModule.moduleHandler.id
    }
}

extension ProviderModule {
    public func compiled<T>(
        _ ctx: PartoutLoggerContext,
        withTemplate templateType: T.Type,
        userInfo: T.UserInfo?
    ) throws -> Module where T: ProviderTemplateCompiler & Decodable {
        guard let entity else {
            throw PartoutError(.Providers.missingEntity)
        }
        let template = try entity.preset.template(ofType: templateType)
        let options: T.Options? = try options(for: providerModuleType)
        return try template.compiled(
            ctx,
            moduleId: id,
            entity: entity,
            options: options,
            userInfo: userInfo
        )
    }
}
