// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonLibrary
import Foundation

final class MockAppProcessor {
    private let iapManager: IAPManager

    init(iapManager: IAPManager) {
        self.iapManager = iapManager
    }
}

extension MockAppProcessor: ProfileProcessor {
    func isIncluded(_ profile: Profile) -> Bool {
        true
    }

    func requiredFeatures(_ profile: Profile) -> Set<ABI.AppFeature>? {
        nil
    }

    func willRebuild(_ builder: Profile.Builder) throws -> Profile.Builder {
        builder
    }
}

extension MockAppProcessor: AppTunnelProcessor {
    func title(for profile: Profile) -> String {
        "Passepartout.Mock: \(profile.name)"
    }

    func willInstall(_ profile: Profile) throws -> Profile {
        profile
    }
}
