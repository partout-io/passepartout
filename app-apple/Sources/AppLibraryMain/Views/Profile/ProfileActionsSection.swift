// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonLibrary
import SwiftUI

struct ProfileActionsSection: View {
    @Environment(IAPObservable.self)
    private var iapObservable

    @Environment(\.dismissProfile)
    private var dismissProfile

    let profileObservable: ProfileObservable

    let profileEditor: ProfileEditor

    @Binding
    var paywallReason: PaywallReason?

    @State
    private var isConfirmingDeletion = false

    var body: some View {
#if os(iOS)
        Section {
            exportButton
            shareButton
            purchaseSharingButton
        }
        Section {
            uuidView
        }
        Section {
            removeContent()
                .themeActionButton()
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
        profileObservable.profile(withId: profileId) != nil
    }

    var uuidView: some View {
        UUIDText(uuid: profileId)
    }

    var exportButton: some View {
        ProfileExportButton(editor: profileEditor)
    }

    var shareButton: some View {
        ProfileShareButton(editor: profileEditor)
    }

    var purchaseSharingButton: some View {
        PurchaseRequiredView(
            requiring: [.sharing],
            reason: $paywallReason,
            title: Strings.Views.Profile.Rows.purchaseSharingFeatures,
            force: false
        )
    }

    func removeContent() -> some View {
        profileObservable.profile(withId: profileId)
            .map { _ in
                removeButton
                    .themeConfirmation(
                        isPresented: $isConfirmingDeletion,
                        title: Strings.Global.Actions.delete,
                        isDestructive: true,
                        action: {
                            Task {
                                dismissProfile()
                                await profileObservable.remove(withId: profileId)
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
