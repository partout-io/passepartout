// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

// FIXME: ###, KeyValueManager (rename PreferencesManager to something else)

import AppABI
import CommonABI_C
import CommonABI
import Observation

@MainActor @Observable
final class PreferencesObserver: ABIObserver {
    func onUpdate(_ event: ABI.Event) {
    }
}

// MARK: - State

//public func contains(_ key: String) -> Bool
//public func object<T>(forKey key: String) -> T?
//public func set<T>(_ value: T?, forKey key: String)
//public func removeObject(forKey key: String)
//public subscript<T>(_ key: String) -> T?
