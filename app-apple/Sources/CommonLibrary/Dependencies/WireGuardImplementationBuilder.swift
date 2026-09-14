// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import Partout

struct WireGuardImplementationBuilder: Sendable {
    private let configBlock: @Sendable () -> Set<ABI.ConfigFlag>
    private let validateBlock: @Sendable (String) throws -> Void

    init(
        configBlock: @escaping @Sendable () -> Set<ABI.ConfigFlag>,
        validateBlock: @escaping @Sendable (String) throws -> Void
    ) {
        self.configBlock = configBlock
        self.validateBlock = validateBlock
    }

    func build() -> WireGuardModule.Implementation {
        WireGuardModule.Implementation(
            keyGenerator: StandardWireGuardKeyGenerator(),
            validateBlock: validateBlock
        )
    }
}
