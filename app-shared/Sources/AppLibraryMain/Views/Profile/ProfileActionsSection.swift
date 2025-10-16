// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonLibrary
import SwiftUI

struct ProfileActionsSection: View {

    @Environment(\.dismissProfile)
    private var dismissProfile

    let profileManager: ProfileManager

    let profileEditor: ProfileEditor

    @State
    private var isConfirmingDeletion = false

    var body: some View {
#if os(iOS)
        Section {
            UUIDText(uuid: profileId)
        }
        Section {
            removeContent()
                .frame(maxWidth: .infinity, alignment: .center)
        }
#else
        if isExistingProfile {
            Section {
                uuidView
                ThemeTrailingContent(content: removeContent)
            }
        } else {
            uuidView
        }
#endif
    }
}

private extension ProfileActionsSection {
    var isExistingProfile: Bool {
        profileManager.profile(withId: profileId) != nil
    }

    var uuidView: some View {
        UUIDText(uuid: profileId)
    }

    func removeContent() -> some View {
        profileManager.profile(withId: profileId)
            .map { _ in
                removeButton
                    .themeConfirmation(
                        isPresented: $isConfirmingDeletion,
                        title: Strings.Global.Actions.delete,
                        isDestructive: true,
                        action: {
                            Task {
                                dismissProfile()
                                await profileManager.remove(withId: profileId)
                            }
                        }
                    )
            }
    }

    var removeButton: some View {
        Button(Strings.Views.Profile.Rows.deleteProfile, role: .destructive) {
            isConfirmingDeletion = true
        }
    }
}

private extension ProfileActionsSection {
    var profileId: Profile.ID {
        profileEditor.profile.id
    }
}
