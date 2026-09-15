// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import Partout

/// Provides ``Module`` centralized operations.
public protocol ModuleRegistry: Sendable {
    func implementation(for moduleType: ModuleType) -> ModuleImplementation?
}
