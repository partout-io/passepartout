// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import Partout

extension IAPManager {
    public func verify(_ profile: Profile, extra: Set<ABI.AppFeature>? = nil) throws {
        var features = profile.features
        extra?.forEach {
            features.insert($0)
        }
        try verify(features)
    }

    public func verify(_ features: Set<ABI.AppFeature>) throws {
#if os(tvOS)
        guard isEligible(for: .appleTV) else {
            throw AppError.ineligibleProfile(features.union([.appleTV]))
        }
#endif
        let requiredFeatures = features.filter {
            !isEligible(for: $0)
        }
        guard requiredFeatures.isEmpty else {
            throw ABI.AppError.ineligibleProfile(requiredFeatures)
        }
    }
}
