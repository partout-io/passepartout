// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonLibrary
import Foundation

extension LegacyAppCoordinator {
    enum ModalRoute: Identifiable {
        case editProfile
        case editProviderEntity(Profile, Bool, Module)
        case importProfileQR
        case importProfileText
        case interactiveLogin
        case settings
        case systemExtension

        var id: Int {
            switch self {
            case .editProfile: return 1
            case .editProviderEntity: return 2
            case .importProfileQR: return 3
            case .importProfileText: return 4
            case .interactiveLogin: return 5
            case .settings: return 6
            case .systemExtension: return 7
            }
        }

        func options() -> ThemeModalOptions {
            var options = ThemeModalOptions()
            options.size = size
            options.isFixedWidth = isFixedWidth
            options.isFixedHeight = isFixedHeight
            options.isInteractive = isInteractive
            return options
        }
    }

    enum ConfirmationAction {
        case deleteProfile(ProfilePreview)
    }
}

extension LegacyAppCoordinator.ModalRoute: Equatable {
    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.id == rhs.id
    }
}

private extension LegacyAppCoordinator.ModalRoute {
    var size: ThemeModalSize {
        switch self {
        case .interactiveLogin:
            return .custom(width: 500, height: 200)
        case .systemExtension:
            return .small
        default:
            return .large
        }
    }

    var isFixedWidth: Bool {
        false
    }

    var isFixedHeight: Bool {
        false
    }

    var isInteractive: Bool {
        switch self {
        case .editProfile:
            return false
        default:
            return true
        }
    }
}
