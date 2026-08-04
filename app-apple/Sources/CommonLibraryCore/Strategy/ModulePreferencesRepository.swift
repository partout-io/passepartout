// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import Partout

@MainActor
public protocol ModulePreferencesRepository {
    func isExcludedEndpoint(_ endpoint: ExtendedEndpoint) -> Bool

    func addExcludedEndpoint(_ endpoint: ExtendedEndpoint)

    func removeExcludedEndpoint(_ endpoint: ExtendedEndpoint)

    func erase()

    func save() throws
}
