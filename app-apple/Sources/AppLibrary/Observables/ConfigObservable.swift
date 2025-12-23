// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonLibrary
import Observation

@MainActor @Observable
public final class ConfigObservable {
    private let abi: ABIProtocol

    public init(abi: ABIProtocol) {
        self.abi = abi
    }
}
