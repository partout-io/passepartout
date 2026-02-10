// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonLibrary

@MainActor
public protocol TunnelInstallationProviding {
    var profileObservable: ProfileObservable { get }

    var tunnel: TunnelObservable { get }
}
