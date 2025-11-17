// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonLibrary
import Foundation
import Partout

// FIXME: #1594, Improve preferences design
public final class ModulePreferences: ObservableObject, ModulePreferencesRepository {
    private var repository: ModulePreferencesRepository?

    public init() {
    }

    public func setRepository(_ repository: ModulePreferencesRepository?) {
        self.repository = repository
    }

    public func isExcludedEndpoint(_ endpoint: ExtendedEndpoint) -> Bool {
        repository?.isExcludedEndpoint(endpoint) ?? false
    }

    public func addExcludedEndpoint(_ endpoint: ExtendedEndpoint) {
        objectWillChange.send()
        repository?.addExcludedEndpoint(endpoint)
    }

    public func removeExcludedEndpoint(_ endpoint: ExtendedEndpoint) {
        objectWillChange.send()
        repository?.removeExcludedEndpoint(endpoint)
    }

    public func erase() {
        repository?.erase()
    }

    public func save() throws {
        try repository?.save()
    }
}
