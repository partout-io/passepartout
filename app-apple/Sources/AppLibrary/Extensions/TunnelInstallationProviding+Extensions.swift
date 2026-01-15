// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonLibrary
// FIXME: #1594, Drop import

@MainActor
extension TunnelInstallationProviding {
    public var installedProfiles: [ABI.AppProfile] {
        tunnel
            .activeProfiles
            .compactMap {
                profileObservable.profile(withId: $0.key)
            }
    }
}

@MainActor
extension LegacyTunnelInstallationProviding {
    public var installedProfiles: [Profile] {
        tunnel
            .activeProfiles
            .compactMap {
                profileManager.partoutProfile(withId: $0.key)
            }
    }
}
