// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonLibrary
import Foundation

@MainActor
public protocol TunnelInstallationProviding {
    var profileManager: ProfileManager { get }

    var tunnel: ExtendedTunnel { get }
}
