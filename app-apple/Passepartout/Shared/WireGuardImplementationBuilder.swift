// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonLibrary
import Partout

struct WireGuardImplementationBuilder: Sendable {
    private let configBlock: @Sendable () -> Set<ABI.ConfigFlag>

    init(configBlock: @escaping @Sendable () -> Set<ABI.ConfigFlag>) {
        self.configBlock = configBlock
    }

    func build() -> WireGuardModule.Implementation {
        WireGuardModule.Implementation(
            keyGenerator: StandardWireGuardKeyGenerator(),
            importerBlock: { newParser() },
            validatorBlock: { newParser() },
            connectionBlock: {
                let ctx = PartoutLoggerContext($0.profile.id)
                return try WireGuardConnection(ctx, parameters: $0, module: $1)
            }
        )
    }

    private func newParser() -> ModuleImporter & ModuleBuilderValidator {
        pp_log_g(.wireguard, .notice, "WireGuard: Using cross-platform parser")
        return StandardWireGuardParser()
    }
}
