// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonLibrary
import SwiftUI

struct ProfileListView: View, Routable, TunnelInstallationProviding {

    @Environment(\.isUITesting)
    private var isUITesting

    @Environment(\.horizontalSizeClass)
    private var hsClass

    @Environment(\.verticalSizeClass)
    private var vsClass

    @Environment(\.isSearching)
    private var isSearching

    @AppStorage(UIPreference.pinsActiveProfile.key)
    private var pinsActiveProfile = true

    @ObservedObject
    var profileManager: ProfileManager

    @ObservedObject
    var tunnel: ExtendedTunnel

    let errorHandler: ErrorHandler

    var flow: ProfileFlow?

    var body: some View {
        Form {
            Section {
                AppNotWorkingButton(tunnel: tunnel)
            }
            if !isUITesting && !isSearching && pinsActiveProfile {
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
    var allPreviews: [ProfilePreview] {
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
            installedProfiles.first.map {
                ProfileContextMenu(
                    style: .installedProfile,
                    profileManager: profileManager,
                    tunnel: tunnel,
                    preview: .init($0),
                    errorHandler: errorHandler,
                    flow: flow
                )
            }
        }
        .modifier(HideActiveProfileModifier())
    }

    func profileView(for preview: ProfilePreview) -> some View {
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
