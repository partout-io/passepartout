// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

extension Module {
    public var moduleType: ModuleType {
        moduleHandler.id
    }
}

extension ModuleBuilder {
    public var moduleType: ModuleType {
        moduleHandler.id
    }
}

extension Module {
    public func moduleBuilder() -> (any ModuleBuilder)? {
        guard let buildableModule = self as? any BuildableType else {
            return nil
        }
        let builder = buildableModule.builder() as any BuilderType
        return builder as? any ModuleBuilder
    }
}
