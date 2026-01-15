// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonLibrary
import MiniFoundation
import Observation

@MainActor @Observable
public final class ConfigObservable {
    private let abi: AppABIConfigProtocol

    public private(set) var activeFlags: Set<ABI.ConfigFlag>

    public init(abi: AppABIConfigProtocol) {
        self.abi = abi
        activeFlags = []
    }

    public func isActive(_ flag: ABI.ConfigFlag) -> Bool {
        activeFlags.contains(flag)
    }

    public func data(for flag: ABI.ConfigFlag) -> JSON? {
        abi.data(for: flag)
    }

    func onUpdate(_ event: ABI.ConfigEvent) {
        pspLog(.core, .debug, "ConfigObservable.onUpdate(): \(event)")
        switch event {
        case .refresh(let flags):
            activeFlags = flags
        }
    }
}

extension ConfigObservable {
    public var isUsingObservables: Bool {
#if os(tvOS)
        isActive(.observableTV)
#else
        isActive(.observableMain)
#endif
    }
}
