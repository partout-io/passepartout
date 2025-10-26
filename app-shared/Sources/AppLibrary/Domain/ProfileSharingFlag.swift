// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonLibrary
import Foundation

public enum ProfileSharingFlag {
    case shared

    case tv
}

extension ProfileManager {
    public func sharingFlags(for profileId: Profile.ID) -> [ProfileSharingFlag] {
        if isRemotelyShared(profileWithId: profileId) {
            if isAvailableForTV(profileWithId: profileId) {
                return [.tv]
            } else {
                return [.shared]
            }
        }
        return []
    }
}
