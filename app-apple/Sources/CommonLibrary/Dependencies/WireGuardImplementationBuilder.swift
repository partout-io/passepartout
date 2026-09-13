// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import Partout

struct WireGuardImplementationBuilder: Sendable {
    private let configBlock: @Sendable () -> Set<ABI.ConfigFlag>

    init(configBlock: @escaping @Sendable () -> Set<ABI.ConfigFlag>) {
        self.configBlock = configBlock
    }

    func build() -> WireGuardModule.Implementation {
        WireGuardModule.Implementation(
            keyGenerator: StandardWireGuardKeyGenerator()
        )
    }
}
