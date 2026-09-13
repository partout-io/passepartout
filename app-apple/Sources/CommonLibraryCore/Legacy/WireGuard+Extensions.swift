// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import Partout

extension WireGuardModule: ConnectionModule {
}

extension WireGuard.LocalInterface.Builder {
    public init(keyGenerator: WireGuardKeyGenerator) {
        self.init(privateKey: keyGenerator.newPrivateKey())
    }
}

extension WireGuard.Configuration.Builder {
    public init(keyGenerator: WireGuardKeyGenerator) {
        self.init(
            interface: WireGuard.LocalInterface.Builder(keyGenerator: keyGenerator),
            peers: []
        )
    }
}
