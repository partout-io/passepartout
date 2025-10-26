// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonLibrary
import Partout

struct WireGuardImplementationBuilder: Sendable {
    private let configBlock: @Sendable () -> Set<ConfigFlag>

    init(configBlock: @escaping @Sendable () -> Set<ConfigFlag>) {
        self.configBlock = configBlock
    }

    func build() -> WireGuardModule.Implementation {
        WireGuardModule.Implementation(
            keyGenerator: StandardWireGuardKeyGenerator(),
            importerBlock: { newParser() },
            validatorBlock: { newParser() },
            connectionBlock: {
                let configFlags = configBlock()
                let ctx = PartoutLoggerContext($0.profile.id)

                // Use new connection on manual preference or config flag
                if configFlags.contains(.wgCrossConnection) {
                    return try WireGuardConnection(ctx, parameters: $0, module: $1)
                } else {
                    return try LegacyWireGuardConnection(ctx, parameters: $0, module: $1)
                }
            }
        )
    }

    private func newParser() -> ModuleImporter & ModuleBuilderValidator {
        let flags = configBlock()
        let isCrossParser = flags.contains(.wgCrossParser)
        pp_log_g(.wireguard, .notice, "WireGuard: Using \(isCrossParser ? "cross-platform" : "legacy") parser")
        return isCrossParser ? StandardWireGuardParser() : LegacyWireGuardParser()
    }
}
