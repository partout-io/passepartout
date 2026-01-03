// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#if !PSP_CROSS
import Combine
extension PreferencesManager: ObservableObject {}
#endif

@MainActor
public final class PreferencesManager {
    public var modulesRepositoryFactory: (UUID) throws -> ModulePreferencesRepository

    public var providersRepositoryFactory: (ProviderID) throws -> ProviderPreferencesRepository

    public init() {
        modulesRepositoryFactory = { _ in
            DummyModulePreferencesRepository()
        }
        providersRepositoryFactory = { _ in
            DummyProviderPreferencesRepository()
        }
    }
}

extension PreferencesManager {
    public func preferencesRepository(forModuleWithId moduleId: UUID) throws -> ModulePreferencesRepository {
        try modulesRepositoryFactory(moduleId)
    }

    public func preferencesRepository(forProviderWithId providerId: ProviderID) throws -> ProviderPreferencesRepository {
        try providersRepositoryFactory(providerId)
    }
}

// MARK: - Dummy

@MainActor
private final class DummyModulePreferencesRepository: ModulePreferencesRepository {
    func isExcludedEndpoint(_ endpoint: ExtendedEndpoint) -> Bool {
        false
    }

    func addExcludedEndpoint(_ endpoint: ExtendedEndpoint) {
    }

    func removeExcludedEndpoint(_ endpoint: ExtendedEndpoint) {
    }

    func erase() {
    }

    func save() throws {
    }
}

@MainActor
private final class DummyProviderPreferencesRepository: ProviderPreferencesRepository {
    func isFavoriteServer(_ serverId: String) -> Bool {
        false
    }

    func addFavoriteServer(_ serverId: String) {
    }

    func removeFavoriteServer(_ serverId: String) {
    }

    func save() throws {
    }
}
