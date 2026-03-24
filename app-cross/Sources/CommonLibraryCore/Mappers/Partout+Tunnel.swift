// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import Partout

extension ABI.AppTunnelStatus {
    init(status: TunnelStatus, environment: TunnelEnvironmentReader?) {
        // If the tunnel is active and it relies on a connection, map
        // app status from the connection status
        if status == .active,
           let connectionStatus = environment?.environmentValue(forKey: TunnelEnvironmentKeys.connectionStatus) {
            switch connectionStatus {
            case .connecting:
                self = .connecting
            case .connected:
                self = .connected
            case .disconnecting:
                self = .disconnecting
            case .disconnected:
                self = .disconnected
            }
            return
        }
        // Otherwise, map directly to the tunnel status
        self = status.abiStatus
    }
}

extension TunnelStatus {
    var abiStatus: ABI.AppTunnelStatus {
        switch self {
        case .inactive: .disconnected
        case .activating: .connecting
        case .active: .connected
        case .deactivating: .disconnecting
        }
    }
}

extension TunnelActiveProfile {
    func abiInfo(withEnvironment environment: TunnelEnvironmentReader?) -> ABI.AppTunnelInfo {
        ABI.AppTunnelInfo(
            id: id,
            rawStatus: status,
            onDemand: onDemand,
            environment: environment
        )
    }
}

extension DataCount {
    var abiTransfer: ABI.ProfileTransfer {
        ABI.ProfileTransfer(received: Int(received), sent: Int(sent))
    }
}
