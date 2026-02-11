// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonLibrary

@MainActor
extension TunnelInstallationProviding {
    public var installedProfiles: [Profile] {
        tunnel
            .activeProfiles
            .compactMap {
                profileObservable.profile(withId: $0.key)
            }
    }
}
