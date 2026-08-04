// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import Partout

public final class KeychainProfileRepository: ProfileRepository {
    private let keychain: Keychain
    private let coder: ProfileCoder
    private let label: @Sendable (Profile) -> String
    private let profilesSubject: CurrentValueStream<[Profile]>
    private let eventsSubject: PassthroughStream<ProfilesEvent>

    public var profilesPublisher: AsyncStream<[Profile]> {
        profilesSubject.subscribe()
    }

    public var eventsPublisher: AsyncStream<ProfilesEvent> {
        eventsSubject.subscribe()
    }

    public init(
        keychain: Keychain,
        coder: ProfileCoder,
        label: @escaping @Sendable (Profile) -> String
    ) {
        self.keychain = keychain
        self.coder = coder
        self.label = label
        profilesSubject = CurrentValueStream([])
        eventsSubject = PassthroughStream()
    }

    // FIXME: ###, Failures here might break AppContext.onLaunch() irreparably with .couldNotLaunch, should double check
    public func fetchProfiles() async throws -> [Profile] {
        let profiles = try keychain
            .allPasswordReferences()
            .compactMap {
                do {
                    return try keychain.password(forReference: $0)
                } catch {
                    pspLog(.core, .error, "Unable to fetch keychain item from reference: \(error)")
                    return nil
                }
            }
            .compactMap {
                do {
                    return try coder.profile(fromString: $0)
                } catch {
                    pspLog(.core, .error, "Unable to decode profile: \(error)")
                    return nil
                }
            }
        profilesSubject.send(profiles)
        eventsSubject.send(.snapshot(profiles))
        return profiles
    }

    public func saveProfile(_ profile: Profile) async throws {
        let string = try coder.string(fromProfile: profile)
        let fingerprint = profile.attributes.fingerprint?.uuidString
        try keychain.set(
            password: string,
            for: profile.id.uuidString,
            metadata: [
                .label(label(profile)),
                .comment(fingerprint ?? "")
            ]
        )
        // Update existing or add new profile
        var allProfiles = profilesSubject.value
        if let index = allProfiles.firstIndex(where: { $0.id == profile.id }) {
            allProfiles[index] = profile
        } else {
            allProfiles.append(profile)
        }
        profilesSubject.send(allProfiles)
        eventsSubject.send(.changes([
            .upsert(profile)
        ]))
    }

    public func removeProfiles(withIds profileIds: [Profile.ID]) async throws {
        var removedIds: Set<Profile.ID> = []
        profileIds.forEach {
            do {
                try keychain.removePassword(for: $0.uuidString)
                removedIds.insert($0)
            } catch {
                pspLog(.core, .error, "Unable to remove profile \($0) from keychain: \(error)")
            }
        }
        var allProfiles = profilesSubject.value
        // Only skip profiles that were actually removed
        allProfiles.removeAll {
            removedIds.contains($0.id)
        }
        profilesSubject.send(allProfiles)
        eventsSubject.send(.changes(profileIds.map {
            .remove($0)
        }))
    }

    public func removeAllProfiles() async throws {
        assertionFailure("Refusing to bulk remove sensitive data")
    }
}
