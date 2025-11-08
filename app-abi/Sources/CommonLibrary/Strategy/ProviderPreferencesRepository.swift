// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import Foundation

@MainActor
public protocol ProviderPreferencesRepository {
    func isFavoriteServer(_ serverId: String) -> Bool

    func addFavoriteServer(_ serverId: String)

    func removeFavoriteServer(_ serverId: String)

    func save() throws
}
