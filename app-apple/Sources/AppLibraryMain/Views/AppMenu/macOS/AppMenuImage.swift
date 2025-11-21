// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#if os(macOS)

import CommonLibrary
import SwiftUI

public struct AppMenuImage: View {

    @ObservedObject
    private var tunnel: ExtendedTunnel

    public init(tunnel: ExtendedTunnel) {
        self.tunnel = tunnel
    }

    public var body: some View {
        ThemeMenuImage(connectionStatus.imageName)
    }
}

private extension AppMenuImage {
    var connectionStatus: TunnelStatus {
        // TODO: #218, must be per-tunnel
        guard let id = tunnel.activeProfiles.first?.value.id else {
            return .inactive
        }
        return tunnel.connectionStatus(ofProfileId: id)
    }
}

private extension TunnelStatus {
    var imageName: Theme.MenuImageName {
        switch self {
        case .active:
            return .active

        case .inactive:
            return .inactive

        case .activating, .deactivating:
            return .pending
        }
    }
}

#endif
