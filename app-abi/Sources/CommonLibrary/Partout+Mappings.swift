// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonABI

extension Profile {
//    public func uiProfile(sharingFlags: [ABI.ProfileSharingFlag]) -> ABI.Profile {
//        ABI.Profile(
//            id: id.uuidString,
//            name: name,
//            fingerprint: (attributes.fingerprint ?? UUID()).uuidString,
//            sharingFlags: sharingFlags
//        )
//    }

    public func uiHeader(
        sharingFlags: [ABI.ProfileSharingFlag],
        requiredFeatures: Set<ABI.AppFeature>
    ) -> ABI.ProfileHeader {
        ABI.ProfileHeader(
            id: id.uuidString,
            name: name,
            moduleTypes: modules.map(\.moduleType.rawValue),
            fingerprint: (attributes.fingerprint ?? UUID()).uuidString,
            sharingFlags: sharingFlags,
            requiredFeatures: requiredFeatures
        )
    }
}

extension ABI.Profile {
    public var partoutProfile: Profile {
        // FIXME: ###, map for real
        guard let id = UUID(uuidString: id) else {
            fatalError()
        }
        return try! Profile.Builder(
            id: id,
            name: header.name
        ).build()
    }
}
