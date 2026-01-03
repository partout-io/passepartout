// SPDX-FileCopyrightText: 2026 Davide De Rosa
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
}
