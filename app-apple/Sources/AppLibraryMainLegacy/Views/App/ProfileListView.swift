// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonLibrary
import SwiftUI

struct ProfileListView: View, Routable, LegacyTunnelInstallationProviding {
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

    @ObservedObject
    var profileManager: ProfileManager

    @ObservedObject
    var tunnel: TunnelManager

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
                ForEach(allPreviews, content: profileView)
                    .onDelete { offsets in
                        Task {
                            await profileManager.removeProfiles(at: offsets)
                        }
                    }
            } header: {
                ProfilesHeaderView()
            }
        }
        .themeForm()
        .themeAnimation(on: profileManager.isReady, category: .profiles)
        .themeAnimation(on: profileManager.previews, category: .profiles)
    }
}

private extension ProfileListView {
    var allPreviews: [ABI.ProfilePreview] {
        profileManager.previews
    }

    // TODO: #218, move to InstalledProfileView when .multiple
    var headerView: some View {
        InstalledProfileView(
            layout: .list,
            profileManager: profileManager,
            profile: installedProfiles.first,
            tunnel: tunnel,
            errorHandler: errorHandler,
            flow: flow
        )
        .contextMenu {
            if let profile = installedProfiles.first {
                ProfileContextMenu(
                    style: .installedProfile,
                    profileManager: profileManager,
                    tunnel: tunnel,
                    preview: .init(profile),
                    errorHandler: errorHandler,
                    flow: flow
                )
            } else {
                HideActiveProfileButton()
            }
        }
        .modifier(HideActiveProfileModifier())
    }

    func profileView(for preview: ABI.ProfilePreview) -> some View {
        ProfileRowView(
            style: cardStyle,
            profileManager: profileManager,
            tunnel: tunnel,
            preview: preview,
            errorHandler: errorHandler,
            flow: flow
        )
        .contextMenu {
            ProfileContextMenu(
                style: .containerContext,
                profileManager: profileManager,
                tunnel: tunnel,
                preview: preview,
                errorHandler: errorHandler,
                flow: flow
            )
        }
        .id(preview.id)
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
        profileManager: .forPreviews,
        tunnel: .forPreviews,
        errorHandler: .default()
    )
    .withMockEnvironment()
}
