// SPDX-FileCopyrightText: 2026 Davide De Rosa
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
            // ABI concerns
            .environmentObject(context.apiManager)
            .environment(context.appEncoderObservable)
            .environment(context.configObservable)
            .environment(context.iapObservable)
            .environmentObject(context.preferencesManager)
            .environment(context.profileObservable)
            .environment(context.registryObservable)
            .environment(context.versionObservable)
            // View concerns
            .environment(context.appFormatter)
            .environment(context.onboardingObservable)
            .environment(context.userPreferences)
    }

    public func withMockEnvironment() -> some View {
        withEnvironment(from: .forPreviews, theme: Theme())
    }
}
