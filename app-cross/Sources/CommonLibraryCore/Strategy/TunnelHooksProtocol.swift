// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import Partout

@BusinessActor
public protocol TunnelHooksProtocol: Sendable {
    func connect(to profile: Profile) async throws
    func disconnect(from profileId: Profile.ID) async throws
    func isActiveProfile(withId profileId: Profile.ID) -> Bool
    func tunnelStatus(for profileId: Profile.ID) -> TunnelStatus
}
