// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonLibrary
import CommonResources
import Partout

extension Dependencies {
    func appProcessor(
        apiManager: APIManager,
        iapManager: IAPManager,
        registry: Registry
    ) -> DefaultAppProcessor {
        DefaultAppProcessor(
            apiManager: apiManager,
            iapManager: iapManager,
            registry: registry,
            title: profileTitle(for:)
        )
    }

    @Sendable
    func profileTitle(for profile: Profile) -> String {
        String(format: appConfiguration.constants.tunnel.profileTitleFormat, profile.name)
    }
}
