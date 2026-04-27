// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonLibrary
import SwiftUI

struct ProfileListView: View, Routable, TunnelInstallationProviding {
    @Environment(UserPreferencesObservable.self)
    private var userPreferences

    @Environment(\.isUITesting)
    private var isUITesting

    @Environment(\.horizontalSizeClass)
    private var hsClass

    @Environment(\.verticalSizeClass)
    private var vsClass

    @Environment(\.isSearching)
    private var isSearching

    let profileObservable: ProfileObservable

    let tunnel: TunnelObservable

    let errorHandler: ErrorHandler

    var flow: ProfileFlow?

    var body: some View {
        Form {
            Section {
                AppNotWorkingButton(tunnel: tunnel)
            }
            if !isUITesting && !isSearching && userPreferences.pinsActiveProfile {
                headerView
                    .unanimated()
            }
            Section {
                ForEach(allHeaders, content: profileView)
                    .onDelete { offsets in
                        Task {
                            await profileObservable.removeProfiles(at: offsets)
                        }
                    }
            } header: {
                ProfilesHeaderView()
            }
        }
        .themeForm()
        .themeAnimation(on: profileObservable.isReady, category: .profiles)
        .themeAnimation(on: profileObservable.filteredHeaders, category: .profiles)
    }
}

private extension ProfileListView {
    var allHeaders: [ABI.AppProfileHeader] {
        profileObservable.filteredHeaders
    }

    // TODO: #218, move to InstalledProfileView when .multiple
    var headerView: some View {
        InstalledProfileView(
            layout: .list,
            profileObservable: profileObservable,
            header: installedHeaders.first,
            tunnel: tunnel,
            errorHandler: errorHandler,
            flow: flow
        )
        .contextMenu {
            if let header = installedHeaders.first {
                ProfileContextMenu(
                    style: .installedProfile,
                    profileObservable: profileObservable,
                    tunnel: tunnel,
                    header: header,
                    errorHandler: errorHandler,
                    flow: flow
                )
            } else {
                HideActiveProfileButton()
            }
        }
        .modifier(HideActiveProfileModifier())
    }

    func profileView(for header: ABI.AppProfileHeader) -> some View {
        ProfileRowView(
            style: cardStyle,
            profileObservable: profileObservable,
            tunnel: tunnel,
            header: header,
            errorHandler: errorHandler,
            flow: flow
        )
        .contextMenu {
            ProfileContextMenu(
                style: .containerContext,
                profileObservable: profileObservable,
                tunnel: tunnel,
                header: header,
                errorHandler: errorHandler,
                flow: flow
            )
        }
        .id(header.id)
    }
}

private extension ProfileListView {
    var cardStyle: ProfileCardView.Style {
        .compact
    }
}

// MARK: - Previews

#Preview {
    ProfileListView(
        profileObservable: .forPreviews,
        tunnel: .forPreviews,
        errorHandler: .default()
    )
    .withMockEnvironment()
}
