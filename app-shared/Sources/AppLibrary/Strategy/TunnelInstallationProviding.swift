// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonLibrary
import Foundation

@MainActor
public protocol TunnelInstallationProviding {
    var profileManager: ProfileManager { get }

    var tunnel: ExtendedTunnel { get }
}
