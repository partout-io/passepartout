// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import AppAccessibility
import CommonLibrary

import SwiftUI

struct ProfileContextMenu: View, Routable {
    enum Style {
        case installedProfile

        case containerContext

        case infoButton
    }

    let style: Style

    let profileManager: ProfileManager

    @ObservedObject
    var tunnel: ExtendedTunnel

    let preview: ProfilePreview

    let errorHandler: ErrorHandler

    var flow: ProfileFlow?

    var body: some View {
        tunnelRestartButton
        providerConnectToButton
        Divider()
        profileEditButton
        if style == .installedProfile {
            HideActiveProfileButton()
        }
        if style == .containerContext {
            profileDuplicateButton
            profileRemoveButton
        }
    }
}

@MainActor
private extension ProfileContextMenu {
    var profile: Profile? {
        profileManager.profile(withId: preview.id)
    }

    var providerConnectToButton: some View {
        profile.map { profile in
            ProviderConnectToButton(
                profile: profile,
                onTap: {
                    flow?.connectionFlow?.onProviderEntityRequired($0)
                },
                label: {
                    ThemeImageLabel(profile.providerServerSelectionTitle, .profileProvider)
                }
            )
            .uiAccessibility(.App.ProfileMenu.connectTo)
        }
    }

    var tunnelRestartButton: some View {
        TunnelRestartButton(
            tunnel: tunnel,
            profile: profile,
            errorHandler: errorHandler,
            flow: flow?.connectionFlow,
            label: {
                ThemeImageLabel(Strings.Global.Actions.reconnect, .tunnelRestart)
            }
        )
    }

    var profileEditButton: some View {
        Button {
            flow?.onEditProfile(preview)
        } label: {
            ThemeImageLabel(Strings.Global.Actions.edit, .profileEdit)
        }
        .uiAccessibility(.App.ProfileMenu.edit)
    }

    var profileDuplicateButton: some View {
        ProfileDuplicateButton(
            profileManager: profileManager,
            preview: preview,
            errorHandler: errorHandler
        ) {
            ThemeImageLabel(Strings.Global.Actions.duplicate, .contextDuplicate)
        }
    }

    var profileRemoveButton: some View {
        Button(role: .destructive) {
            flow?.onDeleteProfile(preview)
        } label: {
            ThemeImageLabel(Strings.Global.Actions.remove, .contextRemove)
        }
    }
}

private extension Profile {
    var providerServerSelectionTitle: String {
        (attributes.isAvailableForTV == true ?
         Strings.Views.Providers.selectEntity : Strings.Views.App.ProfileContext.connectTo).forMenu
    }
}

#Preview {
    List {
        Menu("Menu") {
            ProfileContextMenu(
                style: .installedProfile,
                profileManager: .forPreviews,
                tunnel: .forPreviews,
                preview: .init(.forPreviews),
                errorHandler: .default()
            )
        }
    }
    .withMockEnvironment()
}
