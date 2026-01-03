// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

extension ABI.AppUserLevel: AppFeatureProviding {
    public var features: [ABI.AppFeature] {
        switch self {
        case .beta:
            return [
                .otp,
                .routing,
                .sharing
            ]

        case .essentials:
            return ABI.AppProduct.Essentials.iOS_macOS.features

        case .complete:
            return ABI.AppFeature.allCases

        default:
            return []
        }
    }
}
