//
//  InstalledProfileView.swift
//  Passepartout
//
//  Created by Davide De Rosa on 9/3/24.
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
import UIAccessibility

struct InstalledProfileView: View, Routable {

    @EnvironmentObject
    private var theme: Theme

    let layout: ProfilesLayout

    let profileManager: ProfileManager

    let profile: Profile?

    let tunnel: ExtendedTunnel

    let errorHandler: ErrorHandler

    var flow: ProfileFlow?

    var body: some View {
        debugChanges()
        return HStack(alignment: .center) {
            cardView
                .uiAccessibility(.App.installedProfile)
            Spacer()
            toggleButton
        }
        .modifier(HeaderModifier(layout: layout))
    }
}

private extension InstalledProfileView {
    var cardView: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack(alignment: .center) {
                if profile != nil {
                    actionableNameView
                    Spacer(minLength: 10)
                } else {
                    nameView()
                }
            }
            Group {
                if profile != nil {
                    statusView
                } else {
                    Text(Strings.Views.App.InstalledProfile.None.status)
                        .foregroundStyle(.secondary)
                }
            }
            .font(.body)
        }
        .modifier(CardModifier(layout: layout))
    }

    var actionableNameView: some View {
        ThemeDisclosableMenu(content: menuContent, label: nameView)
    }

    func nameView() -> some View {
        Text(profile?.name ?? Strings.Views.App.InstalledProfile.None.name)
            .font(.title2)
            .fontWeight(theme.relevantWeight)
            .themeMultiLine(true)
    }

    var statusView: some View {
        HStack {
            providerServerButton
            StatusText(theme: theme, tunnel: tunnel)
        }
    }

    var providerServerButton: some View {
        profile?.providerSelectorButton(onSelect: flow?.connectionFlow?.onProviderEntityRequired)
    }

    var toggleButton: some View {
        TunnelToggle(
            tunnel: tunnel,
            profile: profile,
            errorHandler: errorHandler,
            flow: flow?.connectionFlow
        )
        .labelsHidden()
        .opaque(profile != nil)
    }

    func menuContent() -> some View {
        ProfileContextMenu(
            style: .installedProfile,
            profileManager: profileManager,
            tunnel: tunnel,
            preview: .init(profile ?? .forPreviews),
            errorHandler: errorHandler,
            flow: flow
        )
    }
}

// MARK: - Subviews (observing)

private struct StatusText: View {

    @ObservedObject
    var theme: Theme

    @ObservedObject
    var tunnel: ExtendedTunnel

    var body: some View {
        debugChanges()
        return ConnectionStatusText(tunnel: tunnel)
    }
}

private struct HeaderModifier: ViewModifier {

    @EnvironmentObject
    private var theme: Theme

    let layout: ProfilesLayout

    func body(content: Content) -> some View {
        switch layout {
        case .list:
            content
                .listRowInsets(.init())
#if os(iOS)
                .padding(.horizontal)
#endif

        case .grid:
            content
                .themeGridCell()
        }
    }
}

private struct CardModifier: ViewModifier {
    let layout: ProfilesLayout

    func body(content: Content) -> some View {
        switch layout {
        case .list:
#if os(iOS)
            content
                .padding(.vertical)
#else
            content
#endif

        case .grid:
            content
        }
    }
}

// MARK: - Previews

#Preview("List") {
    Form {
        HeaderView(layout: .list)
        Section {
            ContentView()
        }
    }
    .themeForm()
    .withMockEnvironment()
}

#Preview("Grid") {
    ScrollView {
        VStack {
            HeaderView(layout: .grid)
                .padding(.bottom)
            ContentView()
                .themeGridCell()
        }
        .padding()
    }
    .withMockEnvironment()
}

private struct HeaderView: View {
    let layout: ProfilesLayout

    var body: some View {
        InstalledProfileView(
            layout: layout,
            profileManager: .forPreviews,
            profile: .forPreviews,
            tunnel: .forPreviews,
            errorHandler: .default()
        )
    }
}

private struct ContentView: View {
    var body: some View {
        ForEach(0..<3) { _ in
            ProfileRowView(
                style: .full,
                profileManager: .forPreviews,
                tunnel: .forPreviews,
                preview: .init(.forPreviews),
                errorHandler: .default()
            )
        }
    }
}
