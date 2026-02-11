// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#if os(macOS)

import CommonLibrary
import SwiftUI

public struct AppMenuImage: View {
    private let tunnel: TunnelObservable

    public init(tunnel: TunnelObservable) {
        self.tunnel = tunnel
    }

    public var body: some View {
        ThemeMenuImage(connectionStatus.imageName)
    }
}

private extension AppMenuImage {
    var connectionStatus: ABI.AppProfileStatus {
        // TODO: #218, must be per-tunnel
        guard let id = tunnel.activeProfiles.first?.value.id else {
            return .disconnected
        }
        return tunnel.status(for: id)
    }
}

private extension ABI.AppProfileStatus {
    var imageName: Theme.MenuImageName {
        switch self {
        case .connected:
            return .active

        case .disconnected:
            return .inactive

        case .connecting, .disconnecting:
            return .pending
        }
    }
}

#endif
