// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import Partout

final class MockProfileProcessor: ProfileProcessor {
    var isIncludedCount = 0

    var isIncludedBlock: (Profile) -> Bool = { _ in true }

    var requiredFeaturesCount = 0

    var requiredFeatures: Set<ABI.AppFeature>?

    var willRebuildCount = 0

    func title(for profile: Profile) -> String {
        profile.name
    }

    func isIncluded(_ profile: Profile) -> Bool {
        isIncludedCount += 1
        return isIncludedBlock(profile)
    }

    func requiredFeatures(_ profile: Profile) -> Set<ABI.AppFeature>? {
        requiredFeaturesCount += 1
        return requiredFeatures
    }

    func willRebuild(_ builder: Profile.Builder) throws -> Profile.Builder {
        willRebuildCount += 1
        return builder
    }
}
