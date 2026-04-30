// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import Partout

extension TunnelStatus {
    func considering(_ environment: TunnelEnvironmentReader?) -> TunnelStatus {
        // If the tunnel is active and it relies on a
        // connection, map to the connection status
        if self == .active,
           let connectionStatus = environment?.environmentValue(forKey: TunnelEnvironmentKeys.connectionStatus) {
            switch connectionStatus {
            case .connecting:
                return .activating
            case .connected:
                return .active
            case .disconnecting:
                return .deactivating
            case .disconnected:
                return .inactive
            }
        }
        // Otherwise, map directly to the tunnel status
        return self
    }

    var abiStatus: ABI.AppProfileStatus {
        switch self {
        case .inactive: .disconnected
        case .activating: .connecting
        case .active: .connected
        case .deactivating: .disconnecting
        }
    }
}

extension TunnelSnapshot {
    func abiInfo(withEnvironment environment: TunnelEnvironmentReader?) -> ABI.AppTunnelInfo {
        ABI.AppTunnelInfo(
            id: id.uuidString,
            isEnabled: isEnabled,
            tunnelStatus: status,
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
