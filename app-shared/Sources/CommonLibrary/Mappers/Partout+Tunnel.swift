// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import Partout

extension TunnelStatus {
    var uiStatus: ABI.AppProfile.Status {
        switch self {
        case .inactive: .disconnected
        case .activating: .connecting
        case .active: .connected
        case .deactivating: .disconnecting
        }
    }
}

extension TunnelActiveProfile {
    var uiInfo: ABI.AppProfile.Info {
        ABI.AppProfile.Info(id: id, status: status.uiStatus, onDemand: onDemand)
    }
}

extension DataCount {
    var uiTransfer: ABI.ProfileTransfer {
        ABI.ProfileTransfer(received: Int(received), sent: Int(sent))
    }
}
