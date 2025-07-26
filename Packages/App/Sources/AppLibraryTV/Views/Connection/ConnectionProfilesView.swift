// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import AppAccessibility
import CommonLibrary
import CommonUtils
import CommonWeb
import SwiftUI

struct ConnectionProfilesView: View {

    @ObservedObject
    var profileManager: ProfileManager

    @ObservedObject
    var tunnel: ExtendedTunnel

    @FocusState.Binding
    var focusedField: ConnectionView.Field?

    @ObservedObject
    var errorHandler: ErrorHandler

    var flow: ConnectionFlow?

    var body: some View {
        VStack {
            headerView
                .frame(maxWidth: .infinity, alignment: .leading)
            List {
                ForEach(allPreviews, id: \.id, content: toggleButton(for:))
            }
            .themeList()
            .themeProgress(if: false, isEmpty: !profileManager.hasProfiles) {
                Text(Strings.Views.App.Folders.noProfiles)
                    .themeEmptyMessage()
            }
        }
    }
}

private extension ConnectionProfilesView {
    var allPreviews: [ProfilePreview] {
        profileManager.previews
    }

    var headerView: some View {
        Text(Strings.Views.Tv.ConnectionProfiles.header(Strings.Unlocalized.appName, Strings.Unlocalized.appleTV))
            .textCase(.none)
            .foregroundStyle(.primary)
            .font(.body)
    }

    func toggleButton(for preview: ProfilePreview) -> some View {
        TunnelToggle(
            tunnel: tunnel,
            profile: profileManager.profile(withId: preview.id),
            errorHandler: errorHandler,
            flow: flow,
            label: { isOn, _ in
                Button {
                    isOn.wrappedValue.toggle()
                } label: {
                    toggleView(for: preview)
                }
            }
        )
        .focused($focusedField, equals: .profile(preview.id))
        .uiAccessibility(.App.ProfileList.profile)
    }

    func toggleView(for preview: ProfilePreview) -> some View {
        HStack {
            Text(preview.name)
            Spacer()
            tunnel.statusImageName(ofProfileId: preview.id)
                .map {
                    ThemeImage($0)
                        .opaque(tunnel.isActiveProfile(withId: preview.id))
                }
        }
        .font(.headline)
    }
}

// MARK: - Previews

#Preview("List") {
    ContentPreview(profileManager: .forPreviews)
}

#Preview("Empty") {
    ContentPreview(profileManager: ProfileManager(profiles: []))
}

private struct ContentPreview: View {
    let profileManager: ProfileManager

    @FocusState
    var focusedField: ConnectionView.Field?

    var body: some View {
        ConnectionProfilesView(
            profileManager: profileManager,
            tunnel: .forPreviews,
            focusedField: $focusedField,
            errorHandler: .default()
        )
        .withMockEnvironment()
    }
}
