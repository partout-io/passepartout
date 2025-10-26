// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonLibrary
import Foundation

final class MockProfileProcessor: ProfileProcessor {
    var isIncludedCount = 0

    var isIncludedBlock: (Profile) -> Bool = { _ in true }

    var requiredFeaturesCount = 0

    var requiredFeatures: Set<AppFeature>?

    var willRebuildCount = 0

    func title(for profile: Profile) -> String {
        profile.name
    }

    func isIncluded(_ profile: Profile) -> Bool {
        isIncludedCount += 1
        return isIncludedBlock(profile)
    }

    func preview(from profile: Profile) -> ProfilePreview {
        ProfilePreview(profile)
    }

    func requiredFeatures(_ profile: Profile) -> Set<AppFeature>? {
        requiredFeaturesCount += 1
        return requiredFeatures
    }

    func willRebuild(_ builder: Profile.Builder) throws -> Profile.Builder {
        willRebuildCount += 1
        return builder
    }
}
