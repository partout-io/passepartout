//
//  PreferencesManager.swift
//  Passepartout
//
//  Created by Davide De Rosa on 12/4/24.
//  Copyright (c) 2024 Davide De Rosa. All rights reserved.
//
//  https://github.com/passepartoutvpn
//
//  This file is part of Passepartout.
//
//  Passepartout is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  Passepartout is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with Passepartout.  If not, see <http://www.gnu.org/licenses/>.
//

import CommonUtils
import Foundation
import PassepartoutKit

public final class PreferencesManager: ObservableObject, Sendable {
    private let providersFactory: @Sendable (ProviderID) throws -> ProviderPreferencesRepository

    public init(
        providersFactory: (@Sendable (ProviderID) throws -> ProviderPreferencesRepository)? = nil
    ) {
        self.providersFactory = providersFactory ?? { _ in
            DummyProviderPreferencesRepository()
        }
    }
}

extension PreferencesManager {
    public func preferencesRepository(forProviderWithId providerId: ProviderID) throws -> ProviderPreferencesRepository {
        try providersFactory(providerId)
    }
}

@MainActor
extension PreferencesManager {
    public func preferences(forProviderWithId providerId: ProviderID) throws -> ProviderPreferences {
        let object = ProviderPreferences()
        object.repository = try providersFactory(providerId)
        return object
    }
}

// MARK: - Dummy

private final class DummyProviderPreferencesRepository: ProviderPreferencesRepository {
    var favoriteServers: Set<String> = []

    func isExcludedEndpoint(_ endpoint: ExtendedEndpoint) -> Bool {
        false
    }

    func addExcludedEndpoint(_ endpoint: ExtendedEndpoint) {
    }

    func removeExcludedEndpoint(_ endpoint: ExtendedEndpoint) {
    }

    func save() throws {
    }
}
