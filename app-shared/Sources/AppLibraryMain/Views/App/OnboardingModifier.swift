// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonLibrary
import CommonResources
import SwiftUI

struct OnboardingModifier: ViewModifier {

    @EnvironmentObject
    private var apiManager: APIManager

    @Environment(OnboardingObservable.self)
    private var onboardingObservable

    @EnvironmentObject
    private var profileManager: ProfileManager

    @Environment(\.appConfiguration)
    private var appConfiguration

    @Environment(\.isUITesting)
    private var isUITesting

    @Binding
    var modalRoute: LegacyAppCoordinator.ModalRoute?

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
        case .migrateV3_2_3, .migrateV3_5_15:
            return Strings.Global.Nouns.migration
        case .dropLZOCompression:
            return Strings.Global.Nouns.compression
        default:
            return ""
        }
    }

    @ViewBuilder
    func alertActions(for item: OnboardingStep) -> some View {
        switch item {
        case .community:
            Link(Strings.Onboarding.Community.subscribe, destination: appConfiguration.constants.websites.subreddit)
                .environment(\.openURL, OpenURLAction { _ in
                    advance()
                    return .systemAction
                })
            Button(Strings.Onboarding.Community.dismiss, role: .cancel, action: advance)
        case .migrateV3_2_3:
            Button(Strings.Global.Nouns.ok, action: resetProvidersCache)
        case .migrateV3_5_15:
            Button(Strings.Global.Nouns.ok, action: migrateProfilesToJSON)
        case .dropLZOCompression:
            Button(Strings.Global.Nouns.ok, action: advance)
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
            Text([
                Strings.Onboarding.Migrate323.message,
                Strings.Onboarding.Migrate.message
            ].joined(separator: " "))
        case .migrateV3_5_15:
            Text([
                Strings.Onboarding.Migrate3515.message,
                Strings.Onboarding.Migrate.message
            ].joined(separator: " "))
        case .dropLZOCompression:
            Text(Strings.Onboarding.DropLzo.message)
        default:
            EmptyView()
        }
    }
}

private extension OnboardingModifier {

    // 3.2.3
    func resetProvidersCache() {
        Task {
            await apiManager.resetCacheForAllProviders()
            advance()
        }
    }

    // 3.5.15
    func migrateProfilesToJSON() {
        Task {
            await profileManager.resaveAllProfiles()
            advance()
        }
    }
}

private extension OnboardingModifier {
    func deferCurrentStep() {
        if isUITesting {
            pp_log_g(.App.core, .info, "UI tests: skip onboarding")
            return
        }
        Task {
            try await Task.sleep(for: .milliseconds(300))
            performCurrentStep()
        }
    }

    func performCurrentStep() {
        switch onboardingObservable.step {
        case .community, .migrateV3_2_3, .migrateV3_5_15, .dropLZOCompression:
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
