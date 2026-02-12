// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import Partout

extension Profile {
    public func abiHeader(
        sharingFlags: [ABI.ProfileSharingFlag] = [],
        requiredFeatures: Set<ABI.AppFeature> = []
    ) -> ABI.AppProfileHeader {
        ABI.AppProfileHeader(
            id: id,
            name: name,
            moduleTypes: modules.map(\.moduleType.rawValue),
            fingerprint: (attributes.fingerprint ?? UniqueID()).uuidString,
            sharingFlags: sharingFlags,
            requiredFeatures: requiredFeatures
        )
    }
}
