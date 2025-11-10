// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

extension UI.AppUserLevel: UI.AppFeatureProviding {
    public var features: [UI.AppFeature] {
        switch self {
        case .beta:
            return [
                .otp,
                .routing,
                .sharing
            ]

        case .essentials:
            return UI.AppProduct.Essentials.iOS_macOS.features

        case .complete:
            return UI.AppFeature.allCases

        default:
            return []
        }
    }
}
