// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import AppAccessibility
import CommonLibrary
import SwiftUI

struct ConnectionProfilesView: View {

    @EnvironmentObject
    private var configManager: ConfigManager

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
    var allPreviews: [ABI.ProfilePreview] {
        profileManager.previews
    }

    var headerString: String {
        var list: [String] = [Strings.Views.Tv.ConnectionProfiles.Header.share(Strings.Unlocalized.appName, Strings.Unlocalized.appleTV)]
        list.append(Strings.Views.Tv.ConnectionProfiles.Header.import)
        return list.joined(separator: " ")
    }

    var headerView: some View {
        Text(headerString)
            .textCase(.none)
            .foregroundStyle(.primary)
            .font(.body)
    }

    func toggleButton(for preview: ABI.ProfilePreview) -> some View {
        LegacyTunnelToggle(
            tunnel: tunnel,
            profile: profileManager.partoutProfile(withId: preview.id),
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

    func toggleView(for preview: ABI.ProfilePreview) -> some View {
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
