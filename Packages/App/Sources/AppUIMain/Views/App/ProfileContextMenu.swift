//
//  ProfileContextMenu.swift
//  Passepartout
//
//  Created by Davide De Rosa on 9/3/24.
//  Copyright (c) 2025 Davide De Rosa. All rights reserved.
//
//  https://github.com/passepartoutvpn
//
//  This file is part of Passepartout.
//
//  Passepartout is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  Passepartout is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with Passepartout.  If not, see <http://www.gnu.org/licenses/>.
//

import CommonLibrary
import CommonUtils
import PassepartoutKit
import SwiftUI
import UIAccessibility

struct ProfileContextMenu: View, Routable {
    enum Style {
        case installedProfile

        case containerContext

        case infoButton
    }

    let style: Style

    let profileManager: ProfileManager

    let tunnel: ExtendedTunnel

    let preview: ProfilePreview

    let errorHandler: ErrorHandler

    var flow: ProfileFlow?

    var body: some View {
        tunnelToggleButton
        if style == .installedProfile {
            tunnelRestartButton
        }
        providerConnectToButton
        Divider()
        profileEditButton
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

    var tunnelToggleButton: some View {
        TunnelToggleButton(
            tunnel: tunnel,
            profile: profile,
            nextProfileId: .constant(nil),
            errorHandler: errorHandler,
            flow: flow?.connectionFlow,
            label: { canConnect, _ in
                ThemeImageLabel(
                    canConnect ? Strings.Global.Actions.enable : Strings.Global.Actions.disable,
                    canConnect ? .tunnelEnable : .tunnelDisable
                )
            }
        )
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
        ProfileRemoveButton(
            profileManager: profileManager,
            preview: preview
        ) {
            ThemeImageLabel(Strings.Global.Actions.remove, .contextRemove)
        }
    }
}

private extension Profile {
    var providerServerSelectionTitle: String {
        (attributes.isAvailableForTV == true ?
         Strings.Views.Providers.selectEntity : Strings.Views.App.ProfileContext.connectTo).withTrailingDots
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
