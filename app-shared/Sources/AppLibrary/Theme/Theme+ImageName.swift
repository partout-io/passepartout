// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import Foundation

extension Theme {
    public enum ImageName {
        case add
        case close
        case cloudOff
        case cloudOn
        case contextDuplicate
        case contextRemove
        case copy
        case disclose
        case editableSectionEdit
        case editableSectionRemove
        case externalLink
        case failure
        case favoriteOff
        case favoriteOn
        case filters
        case footerAdd
        case hide
        case info
        case marked
        case moduleConnection
        case moduleOnDemand
        case moduleSettings
        case moreDetails
        case navigate
        case pending
        case profileEdit
        case profileImport
        case profileMigrate
        case profileProvider
        case profilesGrid
        case profilesList
        case progress
        case remove
        case search
        case selectionOff
        case selectionOn
        case settings
        case share
        case show
        case sleeping
        case tip
        case tunnelDisable
        case tunnelEnable
        case tunnelRestart
        case tunnelToggle
        case tunnelUninstall
        case tvOff
        case tvOn
        case undisclose
        case upgrade
        case warning
    }
}

extension Theme.ImageName {
    static var defaultSystemName: (Self) -> String {
        {
            switch $0 {
            case .add: return "plus"
            case .close: return "xmark"
            case .cloudOff: return "icloud.slash"
            case .cloudOn: return "icloud"
            case .contextDuplicate: return "plus.square.on.square"
            case .contextRemove: return "trash"
            case .copy: return "doc.on.doc"
            case .disclose: return "chevron.down"
            case .editableSectionEdit: return "arrow.up.arrow.down"
            case .editableSectionRemove: return "trash"
            case .externalLink: return "arrow.up.right.square"
            case .failure: return "exclamationmark.triangle"
            case .favoriteOff: return "star"
            case .favoriteOn: return "star.fill"
            case .filters: return "line.3.horizontal.decrease"
            case .footerAdd: return "plus.circle"
            case .hide: return "eye.slash"
            case .info: return "info.circle"
            case .marked: return "checkmark"
            case .moduleConnection: return "link"
            case .moduleOnDemand: return "wifi"
            case .moduleSettings: return "globe"
            case .moreDetails: return "ellipsis.circle"
            case .navigate: return "chevron.forward"
            case .pending: return "clock"
            case .profileEdit: return "square.and.pencil"
            case .profileImport: return "square.and.arrow.down"
            case .profileMigrate: return "arrow.up.square"
            case .profileProvider: return "network"
            case .profilesGrid: return "square.grid.2x2"
            case .profilesList: return "rectangle.grid.1x2"
            case .progress: return "clock"
            case .remove: return "minus"
            case .search: return "magnifyingglass"
            case .selectionOff: return "circle"
            case .selectionOn: return "checkmark.circle.fill"
            case .settings: return "gearshape"
            case .share: return "square.and.arrow.up"
            case .show: return "eye"
            case .sleeping: return "powersleep"
            case .tip: return "questionmark.circle"
            case .tunnelDisable: return "arrow.down"
            case .tunnelEnable: return "arrow.up"
            case .tunnelRestart: return "arrow.clockwise"
            case .tunnelToggle: return "power"
            case .tunnelUninstall: return "arrow.uturn.down"
            case .tvOff:
                if #available(iOS 17, macOS 14, tvOS 17, *) {
                    return "tv.slash"
                } else {
                    return "tv"
                }
            case .tvOn: return "tv"
            case .undisclose: return "chevron.up"
            case .upgrade: return "lock"
            case .warning: return "exclamationmark.triangle"
            }
        }
    }
}
