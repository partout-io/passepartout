// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

extension AppUserLevel: AppFeatureProviding {
    public var features: [AppFeature] {
        switch self {
        case .beta:
            return [
                .otp,
                .routing,
                .sharing
            ]

        case .essentials:
            return AppProduct.Essentials.iOS_macOS.features

        case .complete:
            return AppFeature.allCases

        default:
            return []
        }
    }
}
