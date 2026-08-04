// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import NetworkExtension
import Partout

// Only @unchecked for the managersSubscription initialization
public final class NEProfileRepository: ProfileRepository, @unchecked Sendable {
    private let repository: NETunnelManagerRepository

    private let profilesSubject: CurrentValueStream<[Profile]>

    private let publicationMutex = SemaphoreMutex()

    private var managersSubscription: Task<Void, Never>?

    public init(repository: NETunnelManagerRepository) {
        self.repository = repository
        profilesSubject = CurrentValueStream([])

        let stream = repository.managersStream
        managersSubscription = Task { [weak self] in
            for await managers in stream {
                guard !Task.isCancelled else {
                    pspLog(.profiles, .debug, "Cancelled NEProfileRepository.managersStream")
                    return
                }
                self?.onUpdatedManagers(managers)
            }
        }
    }

    public var profilesPublisher: AsyncStream<[Profile]> {
        profilesSubject.subscribe()
    }

    public func fetchProfiles() async throws -> [Profile] {
        let managers = try await repository.fetch()
        let profiles = decodedProfiles(from: managers)
        publishIfChanged(profiles)
        return profiles
    }

    public func saveProfile(_ profile: Profile) async throws {
        try await repository.save(
            profile,
            forConnecting: false,
            options: nil as [String: Sendable]?
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
        let profiles = decodedProfiles(from: managers.values)
        publishIfChanged(profiles)
    }

    func publishIfChanged(_ profiles: [Profile]) {
        publicationMutex.with {
            let previous = profilesSubject.value.reduce(into: [:]) {
                $0[$1.id] = $1
            }
            let updated = profiles.reduce(into: [:]) {
                $0[$1.id] = $1
            }
            guard updated != previous else {
                pspLog(.profiles, .info, "Decoded profiles did not change, skip repository update")
                return
            }
            profilesSubject.send(profiles)
        }
    }

    func decodedProfiles(from managers: any Collection<NETunnelProviderManager>) -> [Profile] {
        var decodingTime = 0.0
        let profiles = managers.compactMap {
            do {
                let startDate = Date()
                let profile = try repository.profile(from: $0)
                let elapsed = -startDate.timeIntervalSinceNow
                decodingTime += elapsed
                return profile
            } catch {
                pspLog(.profiles, .error, "Unable to decode profile from NE manager '\($0.localizedDescription ?? "")': \(error)")
                return nil
            }
        }
        pspLog(.profiles, .info, "Decoded \(managers.count) managers to \(profiles.count) profiles in \(decodingTime) seconds")
        return profiles
    }
}
