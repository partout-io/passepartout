// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import Partout

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
