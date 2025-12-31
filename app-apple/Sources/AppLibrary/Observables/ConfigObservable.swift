// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonLibrary
import Observation

@MainActor @Observable
public final class ConfigObservable {
    private let abi: AppABIProtocol

    public init(abi: AppABIProtocol) {
        self.abi = abi
    }

    public var activeFlags: Set<ABI.ConfigFlag> {
        abi.configActiveFlags
    }

    public func isActive(_ flag: ABI.ConfigFlag) -> Bool {
        abi.configIsActive(flag)
    }

    public func data(for flag: ABI.ConfigFlag) -> JSON? {
        abi.configData(for: flag)
    }
}
