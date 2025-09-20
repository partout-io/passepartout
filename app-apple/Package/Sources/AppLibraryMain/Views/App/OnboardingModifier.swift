// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonLibrary
import SwiftUI

struct OnboardingModifier: ViewModifier {

    @EnvironmentObject
    private var apiManager: APIManager

    @EnvironmentObject
    private var onboardingManager: OnboardingManager

    @EnvironmentObject
    private var migrationManager: MigrationManager

    @Environment(\.isUITesting)
    private var isUITesting

    @Binding
    var modalRoute: AppCoordinator.ModalRoute?

    @State
    private var isAlertPresented = false

    func body(content: Content) -> some View {
        content
            .alert(
                alertTitle(for: onboardingManager.step),
                isPresented: $isAlertPresented,
                presenting: onboardingManager.step,
                actions: alertActions,
                message: alertMessage
            )
            .onLoad(perform: deferCurrentStep)
            .onChange(of: modalRoute) {
                if $0 == nil {
                    advance()
                }
            }
            .onChange(of: isAlertPresented) {
                if !$0 {
                    advance()
                }
            }
    }
}

private extension OnboardingModifier {
    func alertTitle(for item: OnboardingStep?) -> String {
        switch item {
        case .community:
            return Strings.Unlocalized.reddit
        case .migrateV3_2_3:
            return Strings.Global.Nouns.migration
        default:
            return ""
        }
    }

    @ViewBuilder
    func alertActions(for item: OnboardingStep) -> some View {
        switch item {
        case .community:
            Link(Strings.Onboarding.Community.subscribe, destination: Constants.shared.websites.subreddit)
                .environment(\.openURL, OpenURLAction { _ in
                    advance()
                    return .systemAction
                })

            Button(Strings.Onboarding.Community.dismiss, role: .cancel, action: advance)

        case .migrateV3_2_3:
            Button(Strings.Global.Nouns.ok) {
                Task {
                    await apiManager.resetCacheForAllProviders()
                    advance()
                }
            }

        default:
            EmptyView()
        }
    }

    @ViewBuilder
    func alertMessage(for item: OnboardingStep) -> some View {
        switch item {
        case .community:
            Text(Strings.Onboarding.Community.message(Strings.Unlocalized.appName))
        case .migrateV3_2_3:
            Text(Strings.Onboarding.Migrate323.message)
        default:
            EmptyView()
        }
    }
}

private extension OnboardingModifier {
    func deferCurrentStep() {
        if isUITesting {
            pp_log_g(.app, .info, "UI tests: skip onboarding")
            return
        }
        Task {
            try await Task.sleep(for: .milliseconds(300))
            performCurrentStep()
        }
    }

    func performCurrentStep() {
        switch onboardingManager.step {
        case .migrateV3:
            guard migrationManager.hasMigratableProfiles else {
                advance()
                return
            }
            modalRoute = .migrateProfiles
        case .community:
            isAlertPresented = true
        case .migrateV3_2_3:
            isAlertPresented = true
        default:
            if onboardingManager.step < .last {
                advance()
            }
        }
    }

    func advance() {
        onboardingManager.advance()
        deferCurrentStep()
    }
}
