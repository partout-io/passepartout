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

    let header: ABI.AppProfileHeader

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
            header: header,
            tunnel: tunnel,
            onTap: flow?.onEditProfile
        )
        .contentShape(.rect)
        .foregroundStyle(.primary)
    }

    var sharingView: some View {
        ProfileSharingView(
            profileObservable: profileObservable,
            profileId: header.id
        )
        .imageScale(isBigDevice ? .large : .medium)
    }

    var tunnelToggle: some View {
        TunnelToggle(
            tunnel: tunnel,
            header: header,
            errorHandler: errorHandler,
            flow: flow?.connectionFlow
        )
        .labelsHidden()
        .uiAccessibility(.App.profileToggle)
    }
}

private extension ProfileRowView {
    var requiredFeatures: Set<ABI.AppFeature>? {
        profileObservable.requiredFeatures(forProfileWithId: header.id)
    }
}

// MARK: - Previews

#Preview {
    let profile: Profile = .forPreviews
    let profileObservable: ProfileObservable = .forPreviews

    return Form {
        ProfileRowView(
            style: .full,
            profileObservable: profileObservable,
            tunnel: .forPreviews,
            header: profile.abiHeaderWithBogusFlagsAndRequirements(),
            errorHandler: .default()
        )
    }
    .task {
        do {
            try await profileObservable.save(profile, sharingFlag: .shared)
        } catch {
            fatalError(error.localizedDescription)
        }
    }
    .themeForm()
    .withMockEnvironment()
}
