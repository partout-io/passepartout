// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonLibrary
import Foundation
import Observation

@MainActor @Observable
public final class ConfigObservable {
    public private(set) var activeFlags: Set<ABI.ConfigFlag>
    public private(set) var allData: [ABI.ConfigFlag: JSON]

    public init() {
        activeFlags = []
        allData = [:]
    }

    public func isActive(_ flag: ABI.ConfigFlag) -> Bool {
        activeFlags.contains(flag)
    }

    public func data(for flag: ABI.ConfigFlag) -> JSON? {
        allData[flag]
    }

    func onUpdate(_ event: ABI.ConfigEvent) {
        pspLog(.core, .debug, "ConfigObservable.onUpdate(): \(event)")
        switch event {
        case .refresh(let flags, let data):
            activeFlags = flags
            allData = data
        }
    }
}
