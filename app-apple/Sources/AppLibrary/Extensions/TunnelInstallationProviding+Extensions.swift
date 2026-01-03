// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonLibrary
import Foundation
import Partout

@MainActor
extension TunnelInstallationProviding {
    public var installedProfiles: [Profile] {
        tunnel
            .activeProfiles
            .compactMap {
                profileManager.partoutProfile(withId: $0.key)
            }
    }
}
