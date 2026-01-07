// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonLibrary

extension AppTip {
    enum Profile {
        static let buildYourProfile = AppTip(
            id: "build-your-profile",
            titleString: Strings.Tips.Profile.BuildYourProfile.title,
            messageString: Strings.Tips.Profile.BuildYourProfile.message
        )
    }
}
