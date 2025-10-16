// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#if os(macOS)

import CommonLibrary
import SwiftUI

struct ProfileGeneralView: View {
    let profileManager: ProfileManager

    @ObservedObject
    var profileEditor: ProfileEditor

    @Binding
    var path: NavigationPath

    @Binding
    var paywallReason: PaywallReason?

    var flow: ProfileCoordinator.Flow?

    var body: some View {
        Form {
            ProfileNameSection(name: $profileEditor.profile.name)
            profileEditor.shortcutsSections(path: $path)
            ProfileStorageSection(
                profileEditor: profileEditor,
                paywallReason: $paywallReason,
                flow: flow
            )
            ProfileBehaviorSection(profileEditor: profileEditor)
            ProfileActionsSection(
                profileManager: profileManager,
                profileEditor: profileEditor
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
