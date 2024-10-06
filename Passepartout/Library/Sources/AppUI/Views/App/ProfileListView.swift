//
//  ProfileListView.swift
//  Passepartout
//
//  Created by Davide De Rosa on 9/3/24.
//  Copyright (c) 2024 Davide De Rosa. All rights reserved.
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

import AppLibrary
import PassepartoutKit
import SwiftUI
import UtilsLibrary

struct ProfileListView: View, TunnelInstallationProviding {

    @Environment(\.horizontalSizeClass)
    private var hsClass

    @Environment(\.verticalSizeClass)
    private var vsClass

    @Environment(\.isSearching)
    private var isSearching

    @ObservedObject
    var profileManager: ProfileManager

    @ObservedObject
    var tunnel: Tunnel

    let interactiveManager: InteractiveManager

    let errorHandler: ErrorHandler

    let onEdit: (ProfileHeader) -> Void

    @State
    private var nextProfileId: Profile.ID?

    var body: some View {
        debugChanges()
        return ScrollViewReader { scrollProxy in
            Form {
                if !isSearching {
                    headerView(scrollProxy: scrollProxy)
                }
                Group {
                    ForEach(allHeaders, content: profileView)
                        .onDelete { offsets in
                            Task {
                                await profileManager.removeProfiles(at: offsets)
                            }
                        }
                }
                .themeSection(header: Strings.Views.Profiles.Folders.default)
            }
            .themeForm()
        }
    }
}

private extension ProfileListView {
    var allHeaders: [ProfileHeader] {
        profileManager.headers
    }

    func headerView(scrollProxy: ScrollViewProxy) -> some View {
        InstalledProfileView(
            layout: .list,
            profileManager: profileManager,
            profile: currentProfile,
            tunnel: tunnel,
            interactiveManager: interactiveManager,
            errorHandler: errorHandler,
            nextProfileId: $nextProfileId,
            flow: .init(
                onEditProfile: onEdit
            )
        )
        .contextMenu {
            currentProfile.map {
                ProfileContextMenu(
                    profileManager: profileManager,
                    tunnel: tunnel,
                    header: $0.header(),
                    interactiveManager: interactiveManager,
                    errorHandler: errorHandler,
                    isInstalledProfile: true,
                    onEdit: onEdit
                )
            }
        }
    }

    func profileView(for header: ProfileHeader) -> some View {
        ProfileRowView(
            style: cardStyle,
            profileManager: profileManager,
            tunnel: tunnel,
            header: header,
            interactiveManager: interactiveManager,
            errorHandler: errorHandler,
            nextProfileId: $nextProfileId,
            withMarker: true,
            onEdit: onEdit
        )
        .contextMenu {
            ProfileContextMenu(
                profileManager: profileManager,
                tunnel: tunnel,
                header: header,
                interactiveManager: interactiveManager,
                errorHandler: errorHandler,
                isInstalledProfile: false,
                onEdit: onEdit
            )
        }
        .id(header.id)
    }
}

private extension ProfileListView {
    var cardStyle: ProfileCardView.Style {
        if hsClass == .compact || vsClass == .compact {
            return .compact
        } else {
            return .full
        }
    }
}

// MARK: - Previews

#Preview {
    ProfileListView(
        profileManager: .mock,
        tunnel: .mock,
        interactiveManager: InteractiveManager(),
        errorHandler: .default(),
        onEdit: { _ in }
    )
    .withMockEnvironment()
}
