// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonLibrary
import Observation

@MainActor @Observable
public final class ConfigObservable {
    private let abi: AppABIProtocol

    public private(set) var activeFlags: Set<ABI.ConfigFlag>

    public init(abi: AppABIProtocol) {
        self.abi = abi
        activeFlags = []
    }

    public func isActive(_ flag: ABI.ConfigFlag) -> Bool {
        activeFlags.contains(flag)
    }

    public func data(for flag: ABI.ConfigFlag) -> JSON? {
        abi.configData(for: flag)
    }

    public func onUpdate(_ event: ABI.ConfigEvent) {
        abi.log(.core, .debug, "ConfigObservable.onUpdate(): \(event)")
        switch event {
        case .refresh(let flags):
            activeFlags = flags
        }
    }
}
