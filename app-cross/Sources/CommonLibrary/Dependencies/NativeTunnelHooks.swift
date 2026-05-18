// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import Partout

// FIXME: #1816, Implement native tunnel hooks to control the tunnel from the library
public struct NativeTunnelHooks: TunnelHooksProtocol {
    public init() {
    }

    public func connect(to profile: Profile) async throws {
    }

    public func disconnect(from profileId: Profile.ID) async throws {
    }

    public func isActiveProfile(withId profileId: Profile.ID) -> Bool {
        false
    }

    public func tunnelStatus(for profileId: Profile.ID) -> TunnelStatus {
        .inactive
    }
}
