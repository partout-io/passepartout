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
        willSet {
            pp_log_g(.app, .info, "Current step: \(step)")
        }
        didSet {
            kvManager?.set(step.rawValue, forUIPreference: .onboardingStep)
            pp_log_g(.app, .info, "Next step: \(step)")
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
