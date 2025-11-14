// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import Partout

extension Profile {
    func uiHeader(
        sharingFlags: [ProfileSharingFlag],
        requiredFeatures: Set<AppFeature>
    ) -> AppProfileHeader {
        AppProfileHeader(
            id: id,
            name: name,
            moduleTypes: modules.map(\.moduleType.rawValue),
            fingerprint: (attributes.fingerprint ?? UUID()).uuidString,
            sharingFlags: sharingFlags,
            requiredFeatures: requiredFeatures
        )
    }

    func uiProfile(
        sharingFlags: [ProfileSharingFlag],
        requiredFeatures: Set<AppFeature>
    ) -> AppProfile {
        AppProfile(
            native: self
        )
    }
}
