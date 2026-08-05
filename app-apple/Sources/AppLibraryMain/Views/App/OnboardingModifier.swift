// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonLibrary
import SwiftUI

struct OnboardingModifier: ViewModifier {
    @Environment(OnboardingObservable.self)
    private var onboardingObservable

    @Environment(\.appConfiguration)
    private var appConfiguration

    @Environment(\.isUITesting)
    private var isUITesting

    @Binding
    var modalRoute: AppCoordinator.ModalRoute?

    let errorHandler: ErrorHandler

    @State
    private var isAlertPresented = false

    func body(content: Content) -> some View {
        content
            .alert(
                alertTitle(for: onboardingObservable.step),
                isPresented: $isAlertPresented,
                presenting: onboardingObservable.step,
                actions: alertActions,
                message: alertMessage
            )
            .onLoad(perform: deferCurrentStep)
            .onChange(of: modalRoute) {
                if $1 == nil {
                    advance()
                }
            }
    }
}

private extension OnboardingModifier {
    func alertTitle(for item: OnboardingStep?) -> String {
        switch item {
        case .discontinueProviders:
            return Strings.Global.Nouns.providers
        default:
            return ""
        }
    }

    @ViewBuilder
    func alertActions(for item: OnboardingStep) -> some View {
        switch item {
        case .discontinueProviders:
            Button(Strings.Global.Nouns.ok, action: advance)
        default:
            EmptyView()
        }
    }

    @ViewBuilder
    func alertMessage(for item: OnboardingStep) -> some View {
        switch item {
        case .discontinueProviders:
            Text(Strings.Onboarding.Migrate395Providers.message)
        default:
            EmptyView()
        }
    }
}

private extension OnboardingModifier {
    func deferCurrentStep() {
        if isUITesting {
            pspLog(.core, .info, "UI tests: skip onboarding")
            return
        }
        Task {
            try await Task.sleep(for: .milliseconds(300))
            performCurrentStep()
        }
    }

    func performCurrentStep() {
        switch onboardingObservable.step {
        case .discontinueProviders:
            isAlertPresented = true
        default:
            if onboardingObservable.step < .last {
                advance()
            }
        }
    }

    func advance() {
        onboardingObservable.advance()
        deferCurrentStep()
    }
}
