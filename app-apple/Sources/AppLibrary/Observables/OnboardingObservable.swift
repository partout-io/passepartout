// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonLibrary
import Observation
import Partout

@MainActor @Observable
public final class OnboardingObservable {
    private let userPreferences: UserPreferencesObservable?

    private let initialStep: OnboardingStep

    public private(set) var step: OnboardingStep {
        willSet {
            pp_log_g(.App.core, .info, "Current step: \(step)")
        }
        didSet {
            userPreferences?.onboardingStep = step
            pp_log_g(.App.core, .info, "Next step: \(step)")
        }
    }

    public convenience init(initialStep: OnboardingStep? = nil) {
        self.init(userPreferences: nil, initialStep: initialStep)
    }

    public convenience init(userPreferences: UserPreferencesObservable) {
        self.init(userPreferences: userPreferences, initialStep: userPreferences.onboardingStep)
    }

    private init(userPreferences: UserPreferencesObservable?, initialStep: OnboardingStep?) {
        self.userPreferences = userPreferences
        self.initialStep = initialStep ?? .first
        step = self.initialStep
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
