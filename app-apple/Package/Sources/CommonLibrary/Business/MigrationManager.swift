// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import Foundation

public protocol MigrationManagerImporter {
    func importProfile(_ profile: Profile, remotelyShared: Bool) async throws
}

@MainActor
public final class MigrationManager: ObservableObject {
    public struct Simulation {
        public let fakeProfiles: Bool

        public let maxMigrationTime: Double?

        public let randomFailures: Bool

        public init(fakeProfiles: Bool, maxMigrationTime: Double?, randomFailures: Bool) {
            self.fakeProfiles = fakeProfiles
            self.maxMigrationTime = maxMigrationTime
            self.randomFailures = randomFailures
        }
    }

    private let profileStrategy: ProfileMigrationStrategy

    private nonisolated let simulation: Simulation?

    public init(
        profileStrategy: ProfileMigrationStrategy? = nil,
        simulation: Simulation? = nil
    ) {
        self.profileStrategy = profileStrategy ?? DummyProfileStrategy()
        self.simulation = simulation
    }
}

// MARK: - Public interface

extension MigrationManager {
    public var hasMigratableProfiles: Bool {
        profileStrategy.hasMigratableProfiles
    }

    public func fetchMigratableProfiles() async throws -> [MigratableProfile] {
        try await profileStrategy.fetchMigratableProfiles()
    }

    public func migratedProfile(withId profileId: UUID) async throws -> Profile? {
        try await profileStrategy.fetchProfile(withId: profileId)
    }

    public func migratedProfiles(
        _ migratableProfiles: [MigratableProfile],
        onUpdate: @escaping @MainActor (UUID, MigrationStatus) -> Void
    ) async throws -> [Profile] {
        migratableProfiles.forEach {
            onUpdate($0.id, .pending)
        }
        return try await withThrowingTaskGroup(of: Profile?.self, returning: [Profile].self) { group in
            migratableProfiles.forEach { migratable in
                group.addTask {
                    do {
                        try await self.simulateBehavior()
                        guard let profile = try await self.simulateMigrateProfile(withId: migratable.id) else {
                            await onUpdate(migratable.id, .failed)
                            return nil
                        }
                        await onUpdate(migratable.id, .done)
                        return profile
                    } catch {
                        await onUpdate(migratable.id, .failed)
                        return nil
                    }
                }
            }
            var profiles: [Profile] = []
            for try await profile in group {
                guard let profile else {
                    continue
                }
                profiles.append(profile)
            }
            return profiles
        }
    }

    public func importProfiles(
        _ profiles: [Profile],
        into importer: MigrationManagerImporter,
        onUpdate: @escaping @MainActor (UUID, MigrationStatus) -> Void
    ) async {
        profiles.forEach {
            onUpdate($0.id, .pending)
        }
        await withTaskGroup(of: Void.self) { group in
            profiles.forEach { profile in
                group.addTask {
                    do {
                        try await self.simulateBehavior()
                        try await self.simulateSaveProfile(profile, to: importer)
                        await onUpdate(profile.id, .done)
                    } catch {
                        await onUpdate(profile.id, .failed)
                    }
                }
            }
        }
    }

    public func deleteMigratableProfiles(withIds profileIds: Set<UUID>) async throws {
        try await simulateDeleteProfiles(withIds: profileIds)
    }
}

// MARK: - Simulation

private extension MigrationManager {
    func simulateBehavior() async throws {
        guard let simulation else {
            return
        }
        if let maxMigrationTime = simulation.maxMigrationTime {
            try await Task.sleep(for: .seconds(.random(in: 1.0..<maxMigrationTime)))
        }
        if simulation.randomFailures, Bool.random() {
            throw AppError.unknown
        }
    }

    func simulateMigrateProfile(withId profileId: UUID) async throws -> Profile? {
        if simulation?.fakeProfiles ?? false {
            return try? Profile.Builder(id: profileId).tryBuild()
        }
        return try await profileStrategy.fetchProfile(withId: profileId)
    }

    func simulateSaveProfile(_ profile: Profile, to importer: MigrationManagerImporter) async throws {
        if simulation?.fakeProfiles ?? false {
            return
        }
        try await importer.importProfile(profile, remotelyShared: profile.attributes.isAvailableForTV == true)
    }

    func simulateDeleteProfiles(withIds profileIds: Set<UUID>) async throws {
        if simulation?.fakeProfiles ?? false {
            return
        }
        try await profileStrategy.deleteProfiles(withIds: profileIds)
    }
}

// MARK: - Dummy

private final class DummyProfileStrategy: ProfileMigrationStrategy {
    var hasMigratableProfiles: Bool {
        false
    }

    public func fetchMigratableProfiles() async throws -> [MigratableProfile] {
        []
    }

    func fetchProfile(withId profileId: UUID) async throws -> Profile? {
        nil
    }

    func deleteProfiles(withIds profileIds: Set<UUID>) async throws {
    }
}
