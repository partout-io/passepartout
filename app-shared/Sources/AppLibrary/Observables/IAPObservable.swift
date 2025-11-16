// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonLibrary
import Observation

@MainActor @Observable
public final class IAPObservable {
    private let logger: AppLogger
    private let iapManager: IAPManager

    public init(logger: AppLogger, iapManager: IAPManager) {
        self.logger = logger
        self.iapManager = iapManager
    }
}

// MARK: - Actions

extension IAPObservable {
}

// MARK: - State

extension IAPObservable {
}

private extension IAPObservable {
    func observeEvents() {
        //
    }
}
