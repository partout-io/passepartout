// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import AppAccessibility
import CommonLibrary
import SwiftUI

struct ConnectionProfilesView: View {

    @EnvironmentObject
    private var configManager: ConfigManager

    let profileObservable: ProfileObservable

    let tunnel: TunnelObservable

    @FocusState.Binding
    var focusedField: ConnectionView.Field?

    let errorHandler: ErrorHandler

    var flow: ConnectionFlow?

    var body: some View {
        VStack {
            headerView
                .frame(maxWidth: .infinity, alignment: .leading)
            List {
                ForEach(headers, id: \.id, content: toggleButton(for:))
            }
            .themeList()
            .themeProgress(if: false, isEmpty: !profileObservable.hasProfiles) {
                Text(Strings.Views.App.Folders.noProfiles)
                    .themeEmptyMessage()
            }
        }
    }
}

private extension ConnectionProfilesView {
    var headers: [ABI.AppProfileHeader] {
        profileObservable.filteredHeaders
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

    func toggleButton(for header: ABI.AppProfileHeader) -> some View {
        TunnelToggle(
            tunnel: tunnel,
            profile: profileObservable.profile(withId: header.id),
            errorHandler: errorHandler,
            flow: flow,
            label: { isOn, _ in
                Button {
                    isOn.wrappedValue.toggle()
                } label: {
                    toggleView(for: header)
                }
            }
        )
        .focused($focusedField, equals: .profile(header.id))
        .uiAccessibility(.App.ProfileList.profile)
    }

    func toggleView(for header: ABI.AppProfileHeader) -> some View {
        HStack {
            Text(header.name)
            Spacer()
            tunnel.statusImageName(ofProfileId: header.id)
                .map {
                    ThemeImage($0)
                        .opaque(tunnel.isActiveProfile(withId: header.id))
                }
        }
        .font(.headline)
    }
}

// MARK: - Previews

// FIXME: #1594, Previews
//#Preview("List") {
//    ContentPreview(profileObservable: .forPreviews)
//}
//
//#Preview("Empty") {
//    ContentPreview(profileObservable: ProfileManager(profiles: []))
//}
//
//private struct ContentPreview: View {
//    let profileObservable: ProfileObservable
//
//    @FocusState
//    var focusedField: ConnectionView.Field?
//
//    var body: some View {
//        ConnectionProfilesView(
//            profileObservable: profileObservable,
//            tunnel: .forPreviews,
//            focusedField: $focusedField,
//            errorHandler: .default()
//        )
//        .withMockEnvironment()
//    }
//}
