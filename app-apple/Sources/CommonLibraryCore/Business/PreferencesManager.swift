// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#if canImport(Combine)
import Combine
extension PreferencesManager: ObservableObject {}
#endif

import Partout

@MainActor
public final class PreferencesManager {
    public var modulesRepositoryFactory: (UniqueID) throws -> ModulePreferencesRepository

    public init() {
        modulesRepositoryFactory = { _ in
            DummyModulePreferencesRepository()
        }
    }
}

extension PreferencesManager {
    public func preferencesRepository(forModuleWithId moduleId: UniqueID) throws -> ModulePreferencesRepository {
        try modulesRepositoryFactory(moduleId)
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
