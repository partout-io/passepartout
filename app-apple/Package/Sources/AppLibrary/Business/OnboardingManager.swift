// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonLibrary
import Foundation

@MainActor
public final class OnboardingManager: ObservableObject {
    private let kvManager: KeyValueManager?

    private let initialStep: OnboardingStep

    public private(set) var step: OnboardingStep {
        didSet {
            kvManager?.set(step.rawValue, forUIPreference: .onboardingStep)
        }
    }

    public init(kvManager: KeyValueManager? = nil, initialStep: OnboardingStep? = nil) {
        self.kvManager = kvManager
        self.initialStep = initialStep ?? .first
        step = self.initialStep
    }

    public convenience init(kvManager: KeyValueManager) {
        let initialStep: OnboardingStep?
        if let rawStep = kvManager.string(forUIPreference: .onboardingStep) {
            initialStep = OnboardingStep(rawValue: rawStep)
        } else {
            initialStep = nil
        }
        self.init(kvManager: kvManager, initialStep: initialStep)
    }

    public func advance() {
        pp_log_g(.app, .info, "Current step: \(step)")
        step = step.nextStep
        pp_log_g(.app, .info, "Next step: \(step)")

        // New installs or 2.x.x
        if initialStep < .doneV3 {
            switch step {
            case .migrateV3_2_3, .migrateV3_6_0:
                // Skip steps about 3.2.3 providers or 3.6.0 profiles
                step = .doneV3_6_0
            default:
                break
            }
        }
    }
}

extension OnboardingStep {
    var nextStep: OnboardingStep {
        let all = OnboardingStep.allCases
        guard let index = all.firstIndex(of: self) else {
            fatalError("How can self not be part of allCases?")
        }
        guard index < all.count - 1 else {
            return self
        }
        return all[index + 1]
    }
}
