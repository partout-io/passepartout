// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import Partout

extension Registry {
    /// Returns a ``Registry`` that optionally includes the known module handlers and resolvers.
    public convenience init(
        withKnown: Bool,
        customHandlers: [ModuleHandler] = [],
        allImplementations: [ModuleImplementation] = [],
        resolvedModuleBlock: ResolvedModuleBlock? = nil
    ) {
        let handlers = withKnown ? ModuleHandler.allKnownHandlers + customHandlers : customHandlers
        self.init(
            allHandlers: handlers,
            allImplementations: allImplementations,
            resolvedModuleBlock: resolvedModuleBlock
        )
    }
}
