// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import SwiftUI

@MainActor
extension View {
    public func withEnvironment(from context: AppContext, theme: Theme) -> some View {
        self
            .environment(theme)
            // Constants
            .environment(\.appConfiguration, context.appConfiguration)
            .environment(\.logFormatterBlock) { [weak context] in
                context?.viewLogger.formattedLog(timestamp: $0.timestamp, message: $0.message) ?? $0.message
            }
            // ABI concerns
            .environment(context.appEncoderObservable)
            .environment(context.configObservable)
            .environment(context.iapObservable)
            .environment(context.profileObservable)
            .environment(context.tunnelObservable)
            .environment(context.versionObservable)
            // View concerns
            .environment(context.appFormatter)
            .environment(context.onboardingObservable)
            .environment(context.userPreferences)
            .environment(context.viewLogger)
            // Deprecated
            .environmentObject(context.apiManager)
            .environmentObject(context.configManager)
            .environmentObject(context.iapManager)
            .environmentObject(context.preferencesManager)
            .environmentObject(context.profileManager)
            .environmentObject(context.versionChecker)
    }

    public func withMockEnvironment() -> some View {
        task {
            try? await AppContext.forPreviews.profileManager.observeLocal()
        }
        .withEnvironment(from: .forPreviews, theme: Theme())
    }
}
