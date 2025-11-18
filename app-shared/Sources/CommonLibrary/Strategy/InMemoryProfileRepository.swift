// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import Foundation
import Partout

public final class InMemoryProfileRepository: ProfileRepository, @unchecked Sendable {
    private let profilesSubject: CurrentValueStream<[Profile]>

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
        pp_log_g(.App.profiles, .info, "Save profile to repository: \(profile.id)")
        if let index = profiles.firstIndex(where: { $0.id == profile.id }) {
            profiles[index] = profile
        } else {
            profiles.append(profile)
        }
    }

    public func removeProfiles(withIds ids: [Profile.ID]) {
        pp_log_g(.App.profiles, .info, "Remove profiles from repository: \(ids)")
        let newProfiles = profiles.filter {
            !ids.contains($0.id)
        }
        guard newProfiles.count < profiles.count else {
            return
        }
        profiles = newProfiles
    }

    public func removeAllProfiles() async throws {
        pp_log_g(.App.profiles, .info, "Remove all profiles from repository")
        profiles = []
    }
}
