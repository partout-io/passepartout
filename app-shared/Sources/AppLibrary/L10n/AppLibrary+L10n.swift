// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonLibrary

extension SystemAppearance {
    public var localizedDescription: String {
        let V = Strings.Entities.Ui.SystemAppearance.self
        switch self {
//        case .none: return V.system
        case .light: return V.light
        case .dark: return V.dark
        }
    }
}

extension AppProfile.Status: LocalizableEntity {
    public var localizedDescription: String {
        let V = Strings.Entities.TunnelStatus.self
        switch self {
        case .disconnected:
            return V.inactive
        case .connecting:
            return V.activating
        case .connected:
            return V.active
        case .disconnecting:
            return V.deactivating
        }
    }
}
