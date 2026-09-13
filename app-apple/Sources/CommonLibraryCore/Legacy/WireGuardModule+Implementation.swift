// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

extension WireGuardModule {
    public final class Implementation: ModuleImplementation, Sendable {
        public let moduleType = WireGuardModule.moduleType

        public let keyGenerator: WireGuardKeyGenerator

        public init(
            keyGenerator: WireGuardKeyGenerator
        ) {
            self.keyGenerator = keyGenerator
        }
    }
}
