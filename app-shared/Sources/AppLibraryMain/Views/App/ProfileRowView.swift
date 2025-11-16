// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonLibrary
import SwiftUI

struct ProfileRowView: View, Routable, SizeClassProviding {

    @Environment(Theme.self)
    private var theme

    @Environment(\.horizontalSizeClass)
    var hsClass

    @Environment(\.verticalSizeClass)
    var vsClass

    let style: ProfileCardView.Style

    @ObservedObject
    var profileManager: ProfileManager

    let tunnel: ExtendedTunnel

    let preview: ABI.ProfilePreview

    let errorHandler: ErrorHandler

    var flow: ProfileFlow?

    var body: some View {
        HStack {
            cardView
            Spacer()
            sharingView
            tunnelToggle
        }
        .unanimated()
    }
}

private extension ProfileRowView {
    var cardView: some View {
        ProfileCardView(
            style: style,
            preview: preview,
            tunnel: tunnel,
            onTap: flow?.onEditProfile
        )
        .contentShape(.rect)
        .foregroundStyle(.primary)
    }

    var sharingView: some View {
        ProfileSharingView(
            profileManager: profileManager,
            profileId: preview.id
        )
        .imageScale(isBigDevice ? .large : .medium)
    }

    var tunnelToggle: some View {
        LegacyTunnelToggle(
            tunnel: tunnel,
            profile: profile,
            errorHandler: errorHandler,
            flow: flow?.connectionFlow
        )
        .labelsHidden()
        .uiAccessibility(.App.profileToggle)
    }
}

private extension ProfileRowView {
    var profile: Profile? {
        profileManager.partoutProfile(withId: preview.id)
    }

    var requiredFeatures: Set<ABI.AppFeature>? {
        profileManager.requiredFeatures(forProfileWithId: preview.id)
    }
}

// MARK: - Previews

#Preview {
    let profile: Profile = .forPreviews
    let profileManager: ProfileManager = .forPreviews

    return Form {
        ProfileRowView(
            style: .full,
            profileManager: profileManager,
            tunnel: .forPreviews,
            preview: .init(profile),
            errorHandler: .default()
        )
    }
    .task {
        do {
            try await profileManager.observeRemote(repository: InMemoryProfileRepository())
            try await profileManager.save(profile, isLocal: true, remotelyShared: true)
        } catch {
            fatalError(error.localizedDescription)
        }
    }
    .themeForm()
    .withMockEnvironment()
}
