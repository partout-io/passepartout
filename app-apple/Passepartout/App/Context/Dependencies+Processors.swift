// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonLibrary
import CommonResources

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
            title: profileTitle
        )
    }

    @Sendable
    nonisolated func profileTitle(_ profile: Profile) -> String {
        String(format: Resources.constants.tunnel.profileTitleFormat, profile.name)
    }
}
