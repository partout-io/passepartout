// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import AppABI
import AppABI_C
import Foundation
import Observation

@MainActor @Observable
final class TunnelObserver {
    private(set) var statuses: [ProfileID: TunnelStatusUI]

    init() {
        statuses = [:]
        refresh()
    }

    func refresh() {
        statuses = abi.tunnelGetAll()
    }

    func status(for profileId: ProfileID) -> TunnelStatusUI {
        statuses[profileId] ?? .disconnected
    }

    func setEnabled(_ enabled: Bool, profileId: ProfileID) {
        abi.tunnelSetEnabled(enabled, profileId: profileId)
    }

    func onUpdate() {
        print("onUpdate() called")
        refresh()
    }
}
