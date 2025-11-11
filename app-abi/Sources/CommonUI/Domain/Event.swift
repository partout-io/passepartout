// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

extension ABI {
    public enum Event {
        case profiles(ProfileEvent)
        case tunnel
    }

    public enum ProfileEvent {
        case ready
        case refresh([Identifier: ProfileHeader])
    }
}
