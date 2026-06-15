// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

@MainActor
public protocol ProviderPreferencesRepository {
    func isFavoriteServer(_ serverId: String) -> Bool

    func addFavoriteServer(_ serverId: String)

    func removeFavoriteServer(_ serverId: String)

    func save() throws
}
