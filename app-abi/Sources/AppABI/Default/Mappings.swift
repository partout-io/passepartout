// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonLibrary

extension Profile {
    public func uiHeader(sharingFlags: [UI.ProfileSharingFlag]) -> UI.ProfileHeader {
        UI.ProfileHeader(
            id: id.uuidString,
            name: name,
            moduleTypes: modules.map(\.moduleType.rawValue),
            fingerprint: (attributes.fingerprint ?? UUID()).uuidString,
            sharingFlags: sharingFlags
        )
    }
}

extension UI.Profile {
    public var partoutProfile: PartoutCore.Profile {
        // FIXME: ###, map for real
        try! Profile.Builder().build()
    }
}
