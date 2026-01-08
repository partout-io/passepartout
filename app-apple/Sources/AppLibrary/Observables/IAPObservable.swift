// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonLibrary
import Observation

@MainActor @Observable
public final class IAPObservable {
    private let abi: AppABIIAPProtocol

    public var isEnabled: Bool {
        didSet {
            abi.iapEnable(isEnabled)
        }
    }
    public private(set) var eligibleFeatures: Set<ABI.AppFeature>
    public private(set) var isLoadingReceipt: Bool
    private var subscription: Task<Void, Never>?

    public init(abi: AppABIIAPProtocol) {
        self.abi = abi

        isEnabled = abi.iapIsEnabled()
        eligibleFeatures = []
        isLoadingReceipt = false
    }
}

// MARK: - Actions

extension IAPObservable {
    public func verify(_ profile: ABI.AppProfile, extra: Set<ABI.AppFeature>?) throws {
        try abi.iapVerify(profile, extra: extra)
    }
}

// MARK: - State

extension IAPObservable {
    public var purchasedProducts: Set<ABI.AppProduct> {
        abi.iapPurchasedProducts
    }

    public var isBeta: Bool {
        abi.iapIsBeta
    }

    public func isEligible(for feature: ABI.AppFeature) -> Bool {
        abi.iapIsEligible(for: feature)
    }

    public var isEligibleForFeedback: Bool {
        abi.iapIsEligibleForFeedback
    }

    public var verificationDelayMinutes: Int {
        abi.iapVerificationDelayMinutes
    }

    func onUpdate(_ event: ABI.IAPEvent) {
        switch event {
        case .status(let isEnabled):
            break
        case .eligibleFeatures(let features):
            eligibleFeatures = features
        case .loadReceipt(let isLoading):
            isLoadingReceipt = isLoading
        }
    }
}
