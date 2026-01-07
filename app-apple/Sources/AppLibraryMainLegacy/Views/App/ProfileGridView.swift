// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonLibrary
import SwiftUI

struct ProfileGridView: View, Routable, TunnelInstallationProviding {
    @Environment(UserPreferencesObservable.self)
    private var userPreferences

    @Environment(\.isUITesting)
    private var isUITesting

    @Environment(\.isSearching)
    private var isSearching

    @ObservedObject
    var profileManager: ProfileManager

    @ObservedObject
    var tunnel: ExtendedTunnel

    let errorHandler: ErrorHandler

    var flow: ProfileFlow?

    private let columns: [GridItem] = [GridItem(.adaptive(minimum: 300.0))]

    var body: some View {
        ScrollView {
            VStack(spacing: .zero) {
                AppNotWorkingButton(tunnel: tunnel)
                    .padding(.bottom)
                if !isUITesting && !isSearching && userPreferences.pinsActiveProfile {
                    headerView
                        .padding(.bottom)
                        .unanimated()
                }
                LazyVGrid(columns: columns) {
                    ForEach(allPreviews, content: profileView)
                        .onDelete { offsets in
                            Task {
                                await profileManager.removeProfiles(at: offsets)
                            }
                        }
                }
                .themeGridHeader {
                    ProfilesHeaderView()
                }
            }
            .padding(.horizontal)
#if os(macOS)
            .padding(.top)
#endif
        }
        .themeAnimation(on: profileManager.isReady, category: .profiles)
        .themeAnimation(on: profileManager.previews, category: .profiles)
    }
}

// MARK: - Subviews

private extension ProfileGridView {
    var allPreviews: [ABI.ProfilePreview] {
        profileManager.previews
    }

    // TODO: #218, move to InstalledProfileView when .multiple
    var headerView: some View {
        InstalledProfileView(
            layout: .grid,
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
    }

    func profileView(for preview: ABI.ProfilePreview) -> some View {
        ProfileRowView(
            style: .compact,
            profileManager: profileManager,
            tunnel: tunnel,
            preview: preview,
            errorHandler: errorHandler,
            flow: flow
        )
        .themeGridCell()
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

// MARK: - Previews

#Preview {
    ProfileGridView(
        profileManager: .forPreviews,
        tunnel: .forPreviews,
        errorHandler: .default()
    )
    .themeWindow(width: 600, height: 300)
    .withMockEnvironment()
}
