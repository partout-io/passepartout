// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import Combine
import Foundation
import NetworkExtension
import Partout

public final class NEProfileRepository: ProfileRepository, @unchecked Sendable {
    private let repository: NETunnelManagerRepository & Sendable

    private let title: @Sendable (Profile) -> String

    private let profilesSubject: CurrentValueSubject<[Profile], Never>

    private var managersSubscription: Task<Void, Never>?

    public init(
        repository: NETunnelManagerRepository & Sendable,
        title: @escaping @Sendable (Profile) -> String
    ) {
        self.repository = repository
        self.title = title
        profilesSubject = CurrentValueSubject([])

        managersSubscription = Task { [weak self] in
            for await manager in repository.managersStream {
                guard !Task.isCancelled else {
                    pp_log_g(.App.profiles, .debug, "Cancelled NEProfileRepository.managersStream")
                    return
                }
                self?.onUpdatedManagers(manager)
            }
        }
    }

    public var profilesPublisher: AnyPublisher<[Profile], Never> {
        profilesSubject.eraseToAnyPublisher()
    }

    public func fetchProfiles() async throws -> [Profile] {
        let managers = try await repository.fetch()
        let profiles = managers.compactMap {
            do {
                return try repository.profile(from: $0)
            } catch {
                pp_log_g(.App.profiles, .error, "Unable to decode profile from NE manager '\($0.localizedDescription ?? "")': \(error)")
                return nil
            }
        }
        profilesSubject.send(profiles)
        return profiles
    }

    public func saveProfile(_ profile: Profile) async throws {
        try await repository.save(
            profile,
            forConnecting: false,
            options: nil as [String: Sendable]?,
            title: title
        )
    }

    public func removeProfiles(withIds profileIds: [Profile.ID]) async throws {
        guard !profileIds.isEmpty else {
            return
        }
        for id in profileIds {
            try await repository.remove(profileId: id)
        }
    }

    public func removeAllProfiles() async throws {
        try await removeProfiles(withIds: profilesSubject.value.map(\.id))
    }
}

private extension NEProfileRepository {
    func onUpdatedManagers(_ managers: [Profile.ID: NETunnelProviderManager]) {
        var decodingTime = 0.0
        let profiles = managers.values.compactMap {
            do {
                let startDate = Date()
                let profile = try repository.profile(from: $0)
                let elapsed = -startDate.timeIntervalSinceNow
                decodingTime += elapsed
                return profile
            } catch {
                pp_log_g(.App.profiles, .error, "Unable to decode profile from NE manager '\($0.localizedDescription ?? "")': \(error)")
                return nil
            }
        }
        pp_log_g(.App.profiles, .info, "Decoded \(managers.count) managers to \(profiles.count) profiles in \(decodingTime) seconds")
        profilesSubject.send(profiles)
    }
}
