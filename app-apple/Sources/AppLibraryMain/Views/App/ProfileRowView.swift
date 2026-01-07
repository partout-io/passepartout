// SPDX-FileCopyrightText: 2026 Davide De Rosa
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

    let profileObservable: ProfileObservable

    let tunnel: TunnelObservable

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
            profileObservable: profileObservable,
            profileId: preview.id
        )
        .imageScale(isBigDevice ? .large : .medium)
    }

    var tunnelToggle: some View {
        TunnelToggle(
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
    var profile: ABI.AppProfile? {
        profileObservable.profile(withId: preview.id)
    }

    var requiredFeatures: Set<ABI.AppFeature>? {
        profileObservable.requiredFeatures(forProfileWithId: preview.id)
    }
}

// MARK: - Previews

#Preview {
    let profile = ABI.AppProfile(native: .forPreviews)
    let profileObservable: ProfileObservable = .forPreviews

    return Form {
        ProfileRowView(
            style: .full,
            profileObservable: profileObservable,
            tunnel: .forPreviews,
            preview: ABI.ProfilePreview(profile.native),
            errorHandler: .default()
        )
    }
    .task {
        do {
            // FIXME: ###
//            try await profileObservable.observeRemote(repository: InMemoryProfileRepository())
            try await profileObservable.save(profile, sharingFlag: .shared)
        } catch {
            fatalError(error.localizedDescription)
        }
    }
    .themeForm()
    .withMockEnvironment()
}
