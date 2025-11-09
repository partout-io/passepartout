// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import Foundation

public protocol ProfileRepository {
    var profilesPublisher: AsyncStream<[Profile]> { get }

    func fetchProfiles() async throws -> [Profile]

    func saveProfile(_ profile: Profile) async throws

    func removeProfiles(withIds profileIds: [Profile.ID]) async throws

    func removeAllProfiles() async throws
}
