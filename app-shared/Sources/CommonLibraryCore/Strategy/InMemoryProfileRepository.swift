// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import MiniFoundation
// FIXME: #1594, Drop import (use AppProfile)
import Partout

public final class InMemoryProfileRepository: ProfileRepository {
    private let profilesSubject: CurrentValueStream<UUID, [Profile]>

    public init(profiles: [Profile] = []) {
        profilesSubject = CurrentValueStream(profiles)
    }

    public var profiles: [Profile] {
        get {
            profilesSubject.value
        }
        set {
            profilesSubject.send(newValue)
        }
    }

    public var profilesPublisher: AsyncStream<[Profile]> {
        profilesSubject.subscribe()
    }

    public func fetchProfiles() async throws -> [Profile] {
        profiles
    }

    public func saveProfile(_ profile: Profile) {
        pspLog(.profiles, .info, "Save profile to repository: \(profile.id)")
        if let index = profiles.firstIndex(where: { $0.id == profile.id }) {
            profiles[index] = profile
        } else {
            profiles.append(profile)
        }
    }

    public func removeProfiles(withIds ids: [Profile.ID]) {
        pspLog(.profiles, .info, "Remove profiles from repository: \(ids)")
        let newProfiles = profiles.filter {
            !ids.contains($0.id)
        }
        guard newProfiles.count < profiles.count else {
            return
        }
        profiles = newProfiles
    }

    public func removeAllProfiles() async throws {
        pspLog(.profiles, .info, "Remove all profiles from repository")
        profiles = []
    }
}
