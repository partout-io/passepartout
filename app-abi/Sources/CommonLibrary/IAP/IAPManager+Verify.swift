// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

extension IAPManager {
    public func verify(_ profile: Profile, extra: Set<AppFeature>? = nil) throws {
        var features = profile.features
        extra?.forEach {
            features.insert($0)
        }
        try verify(features)
    }

    public func verify(_ features: Set<AppFeature>) throws {
#if os(tvOS)
        guard isEligible(for: .appleTV) else {
            throw AppError.ineligibleProfile(features.union([.appleTV]))
        }
#endif
        let requiredFeatures = features.filter {
            !isEligible(for: $0)
        }
        guard requiredFeatures.isEmpty else {
            throw AppError.ineligibleProfile(requiredFeatures)
        }
    }
}

extension IAPManager {
    public var verificationDelayMinutes: Int {
        Constants.shared.tunnel.verificationDelayMinutes(isBeta: isBeta)
    }
}
