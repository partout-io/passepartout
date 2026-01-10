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

    let profileObservable: ProfileObservable

    let tunnel: TunnelObservable

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
                                await profileObservable.removeProfiles(at: offsets)
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
        .themeAnimation(on: profileObservable.isReady, category: .profiles)
        .themeAnimation(on: profileObservable.filteredHeaders, category: .profiles)
    }
}

// MARK: - Subviews

private extension ProfileGridView {
    var allPreviews: [ABI.ProfilePreview] {
        profileObservable.filteredHeaders.map {
            ABI.ProfilePreview(id: $0.id, name: $0.name)
        }
    }

    // TODO: #218, move to InstalledProfileView when .multiple
    var headerView: some View {
        InstalledProfileView(
            layout: .grid,
            profileObservable: profileObservable,
            profile: installedProfiles.first,
            tunnel: tunnel,
            errorHandler: errorHandler,
            flow: flow
        )
        .contextMenu {
            if let profile = installedProfiles.first {
                ProfileContextMenu(
                    style: .installedProfile,
                    profileObservable: profileObservable,
                    tunnel: tunnel,
                    preview: .init(profile.native),
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
            profileObservable: profileObservable,
            tunnel: tunnel,
            preview: preview,
            errorHandler: errorHandler,
            flow: flow
        )
        .themeGridCell()
        .contextMenu {
            ProfileContextMenu(
                style: .containerContext,
                profileObservable: profileObservable,
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
        profileObservable: .forPreviews,
        tunnel: .forPreviews,
        errorHandler: .default()
    )
    .themeWindow(width: 600, height: 300)
    .withMockEnvironment()
}
