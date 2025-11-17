// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonLibrary
import CommonResources
import Foundation

@MainActor @Observable
public final class IAPObservable {
    private let logger: AppLogger
    private let iapManager: IAPManager

    public private(set) var isEnabled: Bool
    public private(set) var eligibleFeatures: Set<ABI.AppFeature>
    public private(set) var isLoadingReceipt: Bool
    private var subscription: Task<Void, Never>?

    public init(logger: AppLogger, iapManager: IAPManager) {
        self.logger = logger
        self.iapManager = iapManager

        isEnabled = true
        eligibleFeatures = []
        isLoadingReceipt = false

        observeEvents()
    }
}

// MARK: - Actions

extension IAPObservable {
    public func verify(_ profile: ABI.AppProfile) throws {
        try iapManager.verify(profile.native)
    }
}

// MARK: - State

extension IAPObservable {
    public var isBeta: Bool {
        iapManager.isBeta
    }

    public var verificationDelayMinutes: Int {
        iapManager.verificationDelayMinutes
    }
}

private extension IAPObservable {
    func observeEvents() {
        subscription = Task { [weak self] in
            guard let self else { return }
            for await event in iapManager.didChange.subscribe() {
                switch event {
                case .status(let isEnabled):
                    self.isEnabled = isEnabled
                case .eligibleFeatures(let features):
                    eligibleFeatures = features
                case .loadReceipt(let isLoading):
                    isLoadingReceipt = isLoading
                }
            }
        }
    }
}
