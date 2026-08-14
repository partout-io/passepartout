// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import Partout

public protocol ProfileRepository: Sendable {
    nonisolated var profilesPublisher: AsyncStream<[Profile]> { get }

    func fetchProfiles() async throws -> [Profile]

    func persistProfile(_ profile: Profile) async throws

    func saveProfile(_ profile: Profile) async throws

    func removeProfiles(withIds profileIds: [Profile.ID]) async throws

    func removeAllProfiles() async throws
}

extension ProfileRepository {
    public func saveProfile(_ profile: Profile) async throws {
        try await persistProfile(profile)
    }
}
