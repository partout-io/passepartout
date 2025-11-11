// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import AppABI
import CommonABI_C
import CommonUtils
import SwiftUI

extension AppEnvironment {
    static let forPreviews: AppEnvironment = {
        let configObserver = ConfigObserver()
        let iapObserver = IAPObserver()
        let preferencesObserver = PreferencesObserver()
        let profileObserver = ProfileObserver()
        let tunnelObserver = TunnelObserver()
        return AppEnvironment(
            configObserver: configObserver,
            iapObserver: iapObserver,
            preferencesObserver: preferencesObserver,
            profileObserver: profileObserver,
            tunnelObserver: tunnelObserver
        )
    }()
}

extension ConfigObserver {
    static var forPreviews: ConfigObserver {
        AppEnvironment.forPreviews.configObserver
    }
}

extension IAPObserver {
    static var forPreviews: IAPObserver {
        AppEnvironment.forPreviews.iapObserver
    }
}

extension PreferencesObserver {
    static var forPreviews: PreferencesObserver {
        AppEnvironment.forPreviews.preferencesObserver
    }
}

extension ProfileObserver {
    static var forPreviews: ProfileObserver {
        AppEnvironment.forPreviews.profileObserver
    }
}

extension TunnelObserver {
    static var forPreviews: TunnelObserver {
        AppEnvironment.forPreviews.tunnelObserver
    }
}
