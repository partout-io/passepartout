// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#if !os(tvOS)

import CommonLibrary
#if canImport(LocalAuthentication)
import LocalAuthentication
#endif
import SwiftUI

struct ThemeLockScreenModifier<LockedContent>: ViewModifier where LockedContent: View {
    @Environment(UserPreferencesObservable.self)
    private var userPreferences

    @Environment(Theme.self)
    private var theme

    @ViewBuilder
    let lockedContent: () -> LockedContent

    func body(content: Content) -> some View {
        LockableView(
            locksInBackground: userPreferences.locksInBackground,
            content: {
                content
            },
            lockedContent: lockedContent,
            unlockBlock: Self.unlockScreenBlock
        )
    }

    private static func unlockScreenBlock() async -> Bool {
        let context = LAContext()
        let policy: LAPolicy = .deviceOwnerAuthentication
        var error: NSError?
        guard context.canEvaluatePolicy(policy, error: &error) else {
            return true
        }
        do {
            let isAuthorized = try await context.evaluatePolicy(
                policy,
                localizedReason: Strings.Theme.LockScreen.reason(Strings.Unlocalized.appName)
            )
            return isAuthorized
        } catch {
            return false
        }
    }
}

#endif
