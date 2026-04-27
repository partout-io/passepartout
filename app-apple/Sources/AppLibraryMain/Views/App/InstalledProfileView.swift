// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import AppAccessibility
import CommonLibrary
import SwiftUI

struct InstalledProfileView: View, Routable {
    @Environment(Theme.self)
    private var theme

    let layout: ProfilesLayout

    let profileObservable: ProfileObservable

    let header: ABI.AppProfileHeader?

    let tunnel: TunnelObservable

    let errorHandler: ErrorHandler

    var flow: ProfileFlow?

    var body: some View {
        debugChanges()
        return HStack(alignment: .center) {
            cardView
            Spacer()
            toggleButton
        }
        .modifier(HeaderModifier(layout: layout))
    }
}

private extension InstalledProfileView {
    var profile: Profile? {
        guard let header else { return nil }
        return profileObservable.profile(withId: header.id)
    }

    var cardView: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack(alignment: .center) {
                if let header {
                    actionableNameView(header: header)
                    Spacer(minLength: 10)
                } else {
                    nameView()
                }
            }
            Group {
                if header != nil {
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

    func actionableNameView(header: ABI.AppProfileHeader) -> some View {
        ThemeDisclosableMenu(
            content: {
                menuContent(header: header)
            },
            label: nameView
        )
    }

    func nameView() -> some View {
        Text(header?.name ?? Strings.Views.App.InstalledProfile.None.name)
            .font(.title2)
            .fontWeight(theme.relevantWeight)
            .themeMultiLine(true)
    }

    var statusView: some View {
        HStack {
            providerServerButton
            statusText
        }
    }

    var providerServerButton: some View {
        profile?.providerSelectorButton(
            onSelect: flow?.connectionFlow?.onProviderEntityRequired
        )
    }

    var statusText: some View {
        ConnectionStatusText(tunnel: tunnel, profileId: header?.id)
    }

    var toggleButton: some View {
        TunnelToggle(
            tunnel: tunnel,
            header: header,
            errorHandler: errorHandler,
            flow: flow?.connectionFlow
        )
        .labelsHidden()
        .opaque(header != nil)
    }

    func menuContent(header: ABI.AppProfileHeader) -> some View {
        ProfileContextMenu(
            style: .installedProfile,
            profileObservable: profileObservable,
            tunnel: tunnel,
            header: header,
            errorHandler: errorHandler,
            flow: flow
        )
    }
}

// MARK: - Subviews (observing)

private struct HeaderModifier: ViewModifier {
    @Environment(Theme.self)
    private var theme

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
            profileObservable: .forPreviews,
            header: .forPreviews,
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
                profileObservable: .forPreviews,
                tunnel: .forPreviews,
                header: .forPreviews,
                errorHandler: .default()
            )
        }
    }
}
