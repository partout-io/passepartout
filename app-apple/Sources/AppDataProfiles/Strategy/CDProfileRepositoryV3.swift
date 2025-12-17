// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import Combine
import AppData
import CommonLibrary
import CoreData
import Foundation
import Partout

extension AppData {
    public static func cdProfileRepositoryV3(
        encoder: AppEncoder,
        context: NSManagedObjectContext,
        observingResults: Bool,
        onResultError: (@Sendable (Error) -> CoreDataResultAction)?
    ) -> ProfileRepository {
        let repository = CoreDataRepository<CDProfileV3, Profile>(
            context: context,
            observingResults: observingResults,
            beforeFetch: {
                $0.sortDescriptors = [
                    .init(key: "name", ascending: true, selector: #selector(NSString.caseInsensitiveCompare)),
                    .init(key: "lastUpdate", ascending: false)
                ]
            },
            fromMapper: {
                try fromMapper($0, encoder: encoder)
            },
            toMapper: {
                try toMapper($0, $1, encoder: encoder)
            },
            onResultError: {
                onResultError?($0) ?? .ignore
            }
        )
        return repository
    }
}

private extension AppData {
    static func fromMapper(
        _ cdEntity: CDProfileV3,
        encoder: AppEncoder
    ) throws -> Profile? {
        guard let encoded = cdEntity.encoded else {
            return nil
        }
        return try encoder.profile(fromString: encoded)
    }

    static func toMapper(
        _ profile: Profile,
        _ context: NSManagedObjectContext,
        encoder: AppEncoder
    ) throws -> CDProfileV3 {
        let encoded = try encoder.json(fromProfile: profile)

        let cdProfile = CDProfileV3(context: context)
        cdProfile.uuid = profile.id
        cdProfile.name = profile.name
        cdProfile.encoded = encoded

        // Redundant but convenient
        let attributes = profile.attributes
        cdProfile.isAvailableForTV = attributes.isAvailableForTV.map(NSNumber.init(value:))
        cdProfile.lastUpdate = attributes.lastUpdate
        cdProfile.fingerprint = attributes.fingerprint

        return cdProfile
    }
}

// MARK: - Specialization

extension CDProfileV3: CoreDataUniqueEntity, @unchecked Sendable {
}

extension Profile: UniqueEntity {
    public var uuid: UUID? {
        id
    }
}

extension CoreDataRepository: ProfileRepository where T == Profile {
    public nonisolated var profilesPublisher: AsyncStream<[Profile]> {
        entitiesPublisher.map(\.entities)
    }

    public func fetchProfiles() async throws -> [Profile] {
        try await fetchAllEntities()
    }

    public func saveProfile(_ profile: Profile) async throws {
        try await saveEntities([profile])
    }

    public func removeProfiles(withIds profileIds: [Profile.ID]) async throws {
        try await removeEntities(withIds: profileIds)
    }

    public func removeAllProfiles() async throws {
        try await removeEntities(withIds: nil)
    }
}
