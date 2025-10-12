// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import SwiftUI

@MainActor
extension View {
    public func withEnvironment(from context: AppContext, theme: Theme) -> some View {
        environmentObject(theme)
            .environmentObject(context.apiManager)
            .environmentObject(context.appearanceManager)
            .environmentObject(context.configManager)
            .environment(\.distributionTarget, context.distributionTarget)
            .environmentObject(context.iapManager)
            .environmentObject(context.kvManager)
            .environmentObject(context.migrationManager)
            .environmentObject(context.onboardingManager)
            .environmentObject(context.preferencesManager)
            .environmentObject(context.profileManager)
            .environmentObject(context.registryCoder)
            .environmentObject(context.versionChecker)
    }

    public func withMockEnvironment() -> some View {
        task {
            try? await AppContext.forPreviews.profileManager.observeLocal()
        }
        .withEnvironment(from: .forPreviews, theme: Theme())
    }
}
