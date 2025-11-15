// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonLibrary
import Foundation
import Partout

@MainActor
public final class OnboardingManager: ObservableObject {
    private let kvManager: KeyValueManager?

    private let initialStep: ABI.OnboardingStep

    public private(set) var step: ABI.OnboardingStep {
        willSet {
            pp_log_g(.App.core, .info, "Current step: \(step)")
        }
        didSet {
            kvManager?.set(step.rawValue, forUIPreference: .onboardingStep)
            pp_log_g(.App.core, .info, "Next step: \(step)")
        }
    }

    public init(kvManager: KeyValueManager? = nil, initialStep: ABI.OnboardingStep? = nil) {
        self.kvManager = kvManager
        self.initialStep = initialStep ?? .first
        step = self.initialStep
    }

    public convenience init(kvManager: KeyValueManager) {
        let initialStep: ABI.OnboardingStep?
        if let rawStep = kvManager.string(forUIPreference: .onboardingStep) {
            initialStep = ABI.OnboardingStep(rawValue: rawStep)
        } else {
            initialStep = nil
        }
        self.init(kvManager: kvManager, initialStep: initialStep)
    }

    public func advance() {
        step = step.nextStep

        // New installs or 2.x.x
        if initialStep < .doneV3 {
            switch step {
            case .migrateV3_2_3, .migrateV3_5_15:
                // Skip steps about 3.2.3 providers or 3.5.15 profiles
                step = .doneV3_5_15
            default:
                break
            }
        }
    }
}

extension ABI.OnboardingStep {
    var nextStep: ABI.OnboardingStep {
        let all = ABI.OnboardingStep.allCases
        guard let index = all.firstIndex(of: self) else {
            fatalError("How can self not be part of allCases?")
        }
        guard index < all.count - 1 else {
            return self
        }
        return all[index + 1]
    }
}
