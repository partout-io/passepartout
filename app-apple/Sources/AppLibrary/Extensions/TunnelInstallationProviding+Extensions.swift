// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonLibrary

@MainActor
extension TunnelInstallationProviding {
    public var installedHeaders: [ABI.AppProfileHeader] {
        tunnel
            .activeProfiles
            .compactMap {
                profileObservable.header(withId: $0.key)
            }
    }
}
