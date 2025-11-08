// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import Foundation

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
