// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import Partout

extension Profile {
    public func uiHeader(
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

    public func uiProfile(
        sharingFlags: [ProfileSharingFlag],
        requiredFeatures: Set<AppFeature>
    ) -> AppProfile {
        AppProfile(
            header: uiHeader(
                sharingFlags: sharingFlags,
                requiredFeatures: requiredFeatures
            ),
            native: self
        )
    }
}
