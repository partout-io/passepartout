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
                let ctx = PartoutLoggerContext($0.profile.id)
#if !PSP_CROSS
                let flags = configBlock()
                if flags.contains(.wgCrossV2) {
                    return try _WireGuardConnectionV2(
                        ctx,
                        parameters: $0,
                        module: $1
                    )
                } else {
                    return try _WireGuardConnectionV1(
                        ctx,
                        parameters: $0,
                        module: $1
                    )
                }
#else
                return try _WireGuardConnectionV2(
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
