// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonLibrary
import CommonResources
import Partout

extension Dependencies {
    func appProcessor(
        cfg: ABI.AppConfiguration,
        apiManager: APIManager,
        iapManager: IAPManager,
        registry: Registry
    ) -> DefaultAppProcessor {
        DefaultAppProcessor(
            apiManager: apiManager,
            iapManager: iapManager,
            registry: registry,
            title: {
                profileTitle(cfg: cfg, profile: $0)
            }
        )
    }

    @Sendable
    nonisolated func profileTitle(cfg: ABI.AppConfiguration, profile: Profile) -> String {
        String(format: cfg.constants.tunnel.profileTitleFormat, profile.name)
    }
}
