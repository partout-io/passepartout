// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#if canImport(Darwin)
extension UI {
    public enum Event {
        case profiles(ProfileEvent)
        case tunnel
    }

    public enum ProfileEvent {
        case ready
        case refresh([Identifier: Profile])
        case requiredFeatures([Identifier: Set<AppFeature>])
    }
}
#endif
