// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import Partout

extension TunnelStatus {
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
    public func abiInfo() -> ABI.AppTunnelInfo {
        ABI.AppTunnelInfo(
            id: id,
            isEnabled: isEnabled,
            tunnelStatus: status,
            onDemand: onDemand,
            environment: environment
        )
    }
}

extension DataCount {
    var abiTransfer: ABI.ProfileTransfer {
        ABI.ProfileTransfer(received: Int64(received), sent: Int64(sent))
    }
}
