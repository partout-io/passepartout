// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import Partout

// MARK: - Providers

extension ProfileType where GenericModuleType == Module {
    public var activeProviderModule: ProviderModule? {
        assertSingleActiveProviderModule()
    }

    @discardableResult
    public func assertSingleActiveProviderModule() -> ProviderModule? {
        let activeProviderModules = activeModules.filter {
            $0 is ProviderModule
        }
        assert(activeProviderModules.count <= 1, "More than 1 active provider module?")
        return activeProviderModules.first as? ProviderModule
    }
}
