// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonLibrary
import Observation

@MainActor @Observable
public final class IAPObservable {
    private let abi: AppABIIAPProtocol

    public private(set) var isEnabled: Bool
    public private(set) var eligibleFeatures: Set<ABI.AppFeature>
    public private(set) var isLoadingReceipt: Bool
    private var subscription: Task<Void, Never>?

    public init(abi: AppABIIAPProtocol) {
        self.abi = abi
        isEnabled = abi.isEnabled
        eligibleFeatures = []
        isLoadingReceipt = false
    }
}

// MARK: - Actions

extension IAPObservable {
    public func enable(_ isEnabled: Bool) {
        abi.enable(isEnabled)
    }

    public func verify(_ profile: ABI.AppProfile, extra: Set<ABI.AppFeature>?) throws {
        try abi.verify(profile, extra: extra)
    }
}

// MARK: - State

extension IAPObservable {
    public var purchasedProducts: Set<ABI.AppProduct> {
        abi.purchasedProducts
    }

    public var isBeta: Bool {
        abi.isBeta
    }

    public func isEligible(for feature: ABI.AppFeature) -> Bool {
        abi.isEligible(for: feature)
    }

    public var isEligibleForFeedback: Bool {
        abi.isEligibleForFeedback
    }

    public var verificationDelayMinutes: Int {
        abi.verificationDelayMinutes
    }

    func onUpdate(_ event: ABI.IAPEvent) {
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
