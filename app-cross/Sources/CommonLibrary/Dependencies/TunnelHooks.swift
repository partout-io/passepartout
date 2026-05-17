// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import Partout

#if !PSP_CROSS
public struct SwiftTunnelHooks: TunnelHooksProtocol {
    private let tunnel: Tunnel

    public init(tunnel: Tunnel) {
        self.tunnel = tunnel
    }

    public func connect(to profile: Profile) async throws {
        try await tunnel.install(profile, connect: true, options: nil)
    }

    public func disconnect(from profileId: Profile.ID) async throws {
        try await tunnel.disconnect(from: profileId)
    }

    public func isActiveProfile(withId profileId: Profile.ID) -> Bool {
        tunnel.snapshots.keys.contains(profileId)
    }

    public func tunnelStatus(for profileId: Profile.ID) -> TunnelStatus {
        tunnel.snapshots[profileId]?.status ?? .inactive
    }
}
#endif

// FIXME: ###, Implement native tunnel hooks to control the tunnel from the library
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
