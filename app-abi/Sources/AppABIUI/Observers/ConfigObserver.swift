// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import AppABI
import AppABI_C
import Observation

@MainActor @Observable
final class ConfigObserver: ABIObserver {
    func onUpdate(_ event: psp_event) {
    }
}

// MARK: - Actions
//
//public func refreshBundle() async
//
// MARK: - State
//
//@Published private var bundle: ConfigBundle?
//
//public func isActive(_ flag: ConfigFlag) -> Bool
//public func data(for flag: ConfigFlag) -> JSON?
//public var activeFlags: Set<ConfigFlag>
