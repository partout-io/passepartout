// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#if os(macOS)

import CommonLibrary
import SwiftUI

struct ProfileGeneralView: View {
    let profileManager: ProfileManager

    let profileEditor: ProfileEditor

    @Binding
    var path: NavigationPath

    @Binding
    var paywallReason: PaywallReason?

    var flow: ProfileCoordinator.Flow?

    var body: some View {
        Form {
            ProfileNameSection(name: profileEditor.binding(\.profile.name))
            profileEditor.shortcutsSections(path: $path)
            ProfileStorageSection(
                profileEditor: profileEditor,
                paywallReason: $paywallReason,
                flow: flow
            )
            ProfileBehaviorSection(profileEditor: profileEditor)
            ProfileActionsSection(
                profileManager: profileManager,
                profileEditor: profileEditor,
                paywallReason: $paywallReason
            )
        }
        .themeForm()
    }
}

#Preview {
    ProfileGeneralView(
        profileManager: .forPreviews,
        profileEditor: ProfileEditor(),
        path: .constant(NavigationPath()),
        paywallReason: .constant(nil)
    )
    .withMockEnvironment()
}

#endif
