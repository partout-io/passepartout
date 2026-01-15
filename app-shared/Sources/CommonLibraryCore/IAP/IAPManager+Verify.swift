// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

// FIXME: #1594, Drop import
import Partout

extension IAPManager {
    public func verify(_ profile: ABI.AppProfile, extra: Set<ABI.AppFeature>? = nil) throws {
        try legacyVerify(profile.native)
    }

    @available(*, deprecated, message: "#1594")
    public func legacyVerify(_ profile: Profile, extra: Set<ABI.AppFeature>? = nil) throws {
        var features = profile.features
        extra?.forEach {
            features.insert($0)
        }
        try verify(features)
    }

    public func verify(_ features: Set<ABI.AppFeature>) throws {
#if os(tvOS)
        guard isEligible(for: .appleTV) else {
            throw ABI.AppError.ineligibleProfile(features.union([.appleTV]))
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
