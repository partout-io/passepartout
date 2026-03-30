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
            keyGenerator: StandardWireGuardKeyGenerator(),
            importerBlock: { newParser() },
            validatorBlock: { newParser() },
            connectionBlock: {
                let flags = configBlock()
                let ctx = PartoutLoggerContext($0.profile.id)
#if !PSP_CROSS
                if flags.contains(.wgCrossV2) {
                    return try WireGuardConnection(
                        ctx,
                        parameters: $0,
                        module: $1
                    )
                } else {
                    return try LegacyWireGuardConnection(
                        ctx,
                        parameters: $0,
                        module: $1
                    )
                }
#else
                return try WireGuardConnection(
                    ctx,
                    parameters: $0,
                    module: $1
                )
#endif
            }
        )
    }

    private func newParser() -> ModuleImporter & ModuleBuilderValidator {
        StandardWireGuardParser()
    }
}
