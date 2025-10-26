// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import Foundation

extension AppTip {
    enum Profile {
        static let buildYourProfile = AppTip(
            id: "build-your-profile",
            titleString: Strings.Tips.Profile.BuildYourProfile.title,
            messageString: Strings.Tips.Profile.BuildYourProfile.message
        )
    }
}
