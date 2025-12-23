// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonLibrary
import Observation

@MainActor @Observable
public final class IAPObservable {
    private let abi: ABIProtocol

    public private(set) var isEnabled: Bool
    public private(set) var eligibleFeatures: Set<ABI.AppFeature>
    public private(set) var isLoadingReceipt: Bool
    private var subscription: Task<Void, Never>?

    public init(abi: ABIProtocol) {
        self.abi = abi

        isEnabled = true
        eligibleFeatures = []
        isLoadingReceipt = false
    }
}

// MARK: - Actions

extension IAPObservable {
    public func verify(_ profile: ABI.AppProfile) throws {
        try abi.iapVerify(profile)
    }
}

// MARK: - State

extension IAPObservable {
    public var isBeta: Bool {
        abi.iapIsBeta
    }

    public var verificationDelayMinutes: Int {
        abi.iapVerificationDelayMinutes
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
