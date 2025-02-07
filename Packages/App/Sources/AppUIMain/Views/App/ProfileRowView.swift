//
//  ProfileRowView.swift
//  Passepartout
//
//  Created by Davide De Rosa on 9/5/24.
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

struct ProfileRowView: View, Routable, SizeClassProviding {

    @EnvironmentObject
    private var theme: Theme

    @Environment(\.horizontalSizeClass)
    var hsClass

    @Environment(\.verticalSizeClass)
    var vsClass

    let style: ProfileCardView.Style

    @ObservedObject
    var profileManager: ProfileManager

    let tunnel: ExtendedTunnel

    let preview: ProfilePreview

    let errorHandler: ErrorHandler

    @Binding
    var nextProfileId: Profile.ID?

    let withMarker: Bool

    var flow: ProfileFlow?

    var body: some View {
        VStack(spacing: .zero) {
            Spacer(minLength: .zero)
            HStack {
                Group {
                    if withMarker {
                        markerView
                    }
                    cardView
                }
                Spacer()
                HStack(spacing: 12) {
                    attributesView
                    tunnelToggle
                }
            }
            Spacer(minLength: .zero)
        }
    }
}

private extension ProfileRowView {
    var markerView: some View {
        MarkerView(
            profileId: preview.id,
            nextProfileId: nextProfileId,
            tunnel: tunnel,
            requiredFeatures: requiredFeatures
        )
    }

    var cardView: some View {
        ProfileCardView(
            style: style,
            preview: preview,
            onTap: flow?.onEditProfile
        )
        .contentShape(.rect)
        .foregroundStyle(.primary)

        // FIXME: ###, UI tests
        .uiAccessibility(.App.profileMenu)
    }

    var attributesView: some View {
        ProfileAttributesView(
            attributes: attributes,
            isRemoteImportingEnabled: profileManager.isRemoteImportingEnabled
        )
        .imageScale(.large)
    }

    var tunnelToggle: some View {
        TunnelToggle(
            profile: profileManager.profile(withId: preview.id),
            tunnel: tunnel,
            errorHandler: errorHandler,
            flow: flow?.connectionFlow
        )
        // FIXME: ###, UI tests
        .uiAccessibility(.App.profileToggle)
    }
}

private extension ProfileRowView {
    var profile: Profile? {
        profileManager.profile(withId: preview.id)
    }

    var attributes: [ProfileAttributesView.Attribute] {
        if isTV {
            return [.tv]
        } else if isShared {
            return [.shared]
        }
        return []
    }

    var requiredFeatures: Set<AppFeature>? {
        profileManager.requiredFeatures(forProfileWithId: preview.id)
    }

    var isShared: Bool {
        profileManager.isRemotelyShared(profileWithId: preview.id)
    }

    var isTV: Bool {
        isShared && profileManager.isAvailableForTV(profileWithId: preview.id)
    }
}

// MARK: - Subviews (observing)

private struct MarkerView: View {
    let profileId: Profile.ID

    let nextProfileId: Profile.ID?

    @ObservedObject
    var tunnel: ExtendedTunnel

    let requiredFeatures: Set<AppFeature>?

    var body: some View {
        ZStack {
            ThemeImage(profileId == nextProfileId ? .pending : tunnel.statusImageName)
                .opaque(requiredFeatures == nil && (profileId == nextProfileId || profileId == tunnel.currentProfile?.id))

            if let requiredFeatures {
                PurchaseRequiredView(features: requiredFeatures)
            }
        }
        .frame(width: 24)
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
            errorHandler: .default(),
            nextProfileId: .constant(nil),
            withMarker: false
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
