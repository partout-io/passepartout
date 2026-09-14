// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import Partout

struct OpenVPNImplementationBuilder: Sendable {
    private let distributionTarget: ABI.DistributionTarget

    private let cachesURL: URL

    private let configBlock: @Sendable () -> Set<ABI.ConfigFlag>

    init(
        distributionTarget: ABI.DistributionTarget,
        cachesURL: URL,
        configBlock: @escaping @Sendable () -> Set<ABI.ConfigFlag>
    ) {
        self.distributionTarget = distributionTarget
        self.cachesURL = cachesURL
        self.configBlock = configBlock
    }

    func build() -> OpenVPNModule.Implementation {
        OpenVPNModule.Implementation()
    }
}
