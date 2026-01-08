// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonLibrary
import Foundation

@MainActor
public protocol TunnelInstallationProviding {
    var profileObservable: ProfileObservable { get }

    var tunnel: TunnelObservable { get }
}

@available(*, deprecated, message: "#1594")
@MainActor
public protocol LegacyTunnelInstallationProviding {
    var profileManager: ProfileManager { get }

    var tunnel: TunnelManager { get }
}
