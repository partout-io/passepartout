// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

public enum UIPreference: String, PreferenceProtocol {
    case keepsInMenu
    case lastInfrastructureRefresh
    case locksInBackground
    case onboardingStep
    case onlyShowsFavorites
    case pinsActiveProfile
    case profilesLayout
    case systemAppearance

    public var key: String {
        "UI.\(rawValue)"
    }
}
