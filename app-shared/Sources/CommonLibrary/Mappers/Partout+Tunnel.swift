// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import Partout

extension TunnelStatus {
    var uiStatus: AppProfile.Status {
        switch self {
        case .inactive: .disconnected
        case .activating: .connecting
        case .active: .connected
        case .deactivating: .disconnecting
        }
    }
}

extension TunnelActiveProfile {
    var uiInfo: AppProfile.Info {
        AppProfile.Info(id: id, status: status.uiStatus, onDemand: onDemand)
    }
}

extension DataCount {
    var uiTransfer: ProfileTransfer {
        ProfileTransfer(received: Int(received), sent: Int(sent))
    }
}
