// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonLibrary
import Foundation

@MainActor
extension TunnelInstallationProviding {
    public var installedProfiles: [Profile] {
        tunnel
            .activeProfiles
            .compactMap {
                profileManager.profile(withId: $0.key)
            }
    }
}
