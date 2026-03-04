// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import Partout

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
    var abiInfo: ABI.AppTunnelInfo {
        ABI.AppTunnelInfo(id: id, status: status.abiStatus, onDemand: onDemand)
    }
}

extension DataCount {
    var abiTransfer: ABI.ProfileTransfer {
        ABI.ProfileTransfer(received: Int(received), sent: Int(sent))
    }
}
