// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonLibrary
import SwiftUI

extension ModuleBuilder {

    @MainActor
    public var themeIcon: Theme.ImageName {
        switch moduleType {
        case .openVPN, .wireGuard:
            .moduleConnection
        case .onDemand:
            .moduleOnDemand
        case .dns, .httpProxy, .ip:
            .moduleSettings
        default:
            .moduleSettings
        }
    }
}

extension TunnelStatus {

    @MainActor
    public func color(_ theme: Theme) -> Color {
        switch self {
        case .active:
            return theme.activeColor
        case .activating, .deactivating:
            return theme.pendingColor
        case .inactive:
            return theme.inactiveColor
        }
    }
}

extension TunnelObservable {
    public func statusImageName(ofProfileId profileId: Profile.ID) -> Theme.ImageName? {
        activeProfiles[profileId]?.status.imageName
    }

    public func statusColor(ofProfileId profileId: Profile.ID, _ theme: Theme) -> Color {
        let info = activeProfiles[profileId]
        if lastError(for: profileId) != nil {
            return theme.errorColor
        }
        switch info?.status {
        case .connected:
            return theme.activeColor
        case .connecting, .disconnecting:
            return theme.pendingColor
        case .disconnected, nil:
            return info?.onDemand == true ? theme.pendingColor : theme.inactiveColor
        }
    }
}

private extension ABI.AppTunnelStatus {
    var imageName: Theme.ImageName? {
        switch self {
        case .connected:
            return .marked
        case .connecting, .disconnecting:
            return .pending
        case .disconnected:
            return nil
        }
    }
}
