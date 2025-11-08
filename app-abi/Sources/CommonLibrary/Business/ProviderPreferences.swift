// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonUtils
import Foundation

public final class ProviderPreferences: ObservableObject, ProviderPreferencesRepository {
    private var repository: ProviderPreferencesRepository?

    public init() {
    }

    public func setRepository(_ repository: ProviderPreferencesRepository?) {
        self.repository = repository
    }

    // TODO: #1263, favorites are now regions, rename accordingly
    public func favoriteServers() -> ObservableList<String> {
        ObservableList { [weak self] in
            self?.isFavoriteServer($0) ?? false
        } add: { [weak self] in
            self?.addFavoriteServer($0)
        } remove: { [weak self] in
            self?.removeFavoriteServer($0)
        }
    }

    public func isFavoriteServer(_ serverId: String) -> Bool {
        repository?.isFavoriteServer(serverId) ?? false
    }

    public func addFavoriteServer(_ serverId: String) {
        objectWillChange.send()
        repository?.addFavoriteServer(serverId)
    }

    public func removeFavoriteServer(_ serverId: String) {
        objectWillChange.send()
        repository?.removeFavoriteServer(serverId)
    }

    public func save() throws {
        try repository?.save()
    }
}
