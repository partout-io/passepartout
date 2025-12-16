// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonLibrary
import Observation

@MainActor @Observable
public final class UserPreferencesObservable {
    private let kvManager: KeyValueManager

    public init(kvManager: KeyValueManager) {
        self.kvManager = kvManager
    }
}
