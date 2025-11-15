// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import Partout

extension Profile {
    func uiHeader(
        sharingFlags: [ABI.ProfileSharingFlag],
        requiredFeatures: Set<ABI.AppFeature>
    ) -> ABI.AppProfileHeader {
        ABI.AppProfileHeader(
            id: id,
            name: name,
            moduleTypes: modules.map(\.moduleType.rawValue),
            fingerprint: (attributes.fingerprint ?? UUID()).uuidString,
            sharingFlags: sharingFlags,
            requiredFeatures: requiredFeatures
        )
    }

    func uiProfile(
        sharingFlags: [ABI.ProfileSharingFlag],
        requiredFeatures: Set<ABI.AppFeature>
    ) -> ABI.AppProfile {
        ABI.AppProfile(
            native: self
        )
    }
}
