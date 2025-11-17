// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import SwiftUI

@MainActor
extension View {
    public func withEnvironment(from context: AppContext, theme: Theme) -> some View {
        self
            .environment(theme)
            .environment(context.appearanceObservable)
            .environment(context.appEncoderObservable)
            .environment(\.distributionTarget, context.distributionTarget)
            .environment(context.iapObservable)
            .environment(context.onboardingObservable)
            .environment(context.profileObservable)
            .environment(context.tunnelObservable)
            .environment(context.viewLogger)
            // Redesign
            .environmentObject(context.apiManager)
            .environmentObject(context.preferencesManager)
            // Deprecate
            .environmentObject(context.configManager)
            .environmentObject(context.iapManager)
            .environmentObject(context.kvManager)
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
