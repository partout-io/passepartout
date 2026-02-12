// SPDX-FileCopyrightText: 2026 Davide De Rosa
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

    let profileObservable: ProfileObservable

    let tunnel: TunnelObservable

    let header: ABI.AppProfileHeader

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
    var providerConnectToButton: some View {
        profile.map { profile in
            ProviderConnectToButton(
                header: profile,
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
            header: profile,
            errorHandler: errorHandler,
            flow: flow?.connectionFlow,
            label: {
                ThemeImageLabel(Strings.Global.Actions.reconnect, .tunnelRestart)
            }
        )
    }

    var profileEditButton: some View {
        Button {
            flow?.onEditProfile(header)
        } label: {
            ThemeImageLabel(Strings.Global.Actions.edit, .profileEdit)
        }
        .uiAccessibility(.App.ProfileMenu.edit)
    }

    var profileDuplicateButton: some View {
        ProfileDuplicateButton(
            profileObservable: profileObservable,
            header: header,
            errorHandler: errorHandler
        ) {
            ThemeImageLabel(Strings.Global.Actions.duplicate, .contextDuplicate)
        }
    }

    var profileRemoveButton: some View {
        Button(role: .destructive) {
            flow?.onDeleteProfile(header)
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
                profileObservable: .forPreviews,
                tunnel: .forPreviews,
                header: .forPreviews,
                errorHandler: .default()
            )
        }
    }
    .withMockEnvironment()
}
