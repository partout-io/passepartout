// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonLibrary
import SwiftUI

struct ProfileContainerView: View, Routable {

    @EnvironmentObject
    private var iapManager: IAPManager

    let layout: ProfilesLayout

    let profileManager: ProfileManager

    let tunnel: ExtendedTunnel

    let registry: Registry

    @Binding
    var isImporting: Bool

    let errorHandler: ErrorHandler

    var flow: ProfileFlow?

    var body: some View {
        debugChanges()
        return innerView
            .modifier(ContainerModifier(
                profileManager: profileManager,
                tunnel: tunnel,
                flow: flow
            ))
            .modifier(AppProfileImporterModifier(
                profileManager: profileManager,
                isPresented: $isImporting,
                errorHandler: errorHandler
            ))
            .navigationTitle(Strings.Unlocalized.appName)
    }
}

private extension ProfileContainerView {

    @ViewBuilder
    var innerView: some View {
        switch layout {
        case .list:
            ProfileListView(
                profileManager: profileManager,
                tunnel: tunnel,
                errorHandler: errorHandler,
                flow: flow
            )

        case .grid:
            ProfileGridView(
                profileManager: profileManager,
                tunnel: tunnel,
                errorHandler: errorHandler,
                flow: flow
            )
        }
    }
}

private struct ContainerModifier: ViewModifier {

    @ObservedObject
    var profileManager: ProfileManager

    @ObservedObject
    var tunnel: ExtendedTunnel

    let flow: ProfileFlow?

    @State
    private var search = ""

    func body(content: Content) -> some View {
        debugChanges()
        return content
            .themeProgress(
                if: !profileManager.isReady,
                isEmpty: !profileManager.hasProfiles,
                emptyContent: emptyView
            )
            .searchable(text: $search)
            .onChange(of: search) {
                profileManager.search(byName: $0)
            }
    }

    private func emptyView() -> some View {
        ZStack {
            VStack(spacing: 16) {
                Text(Strings.Views.App.Folders.noProfiles)
                    .themeEmptyMessage(fullScreen: false)
            }
            VStack {
                AppNotWorkingButton(tunnel: tunnel)
                Spacer()
            }
        }
    }
}

// MARK: - Previews

#Preview("List") {
    PreviewView(layout: .list)
}

#Preview("Grid") {
    PreviewView(layout: .grid)
}

private struct PreviewView: View {
    let layout: ProfilesLayout

    var body: some View {
        NavigationStack {
            ProfileContainerView(
                layout: layout,
                profileManager: .forPreviews,
                tunnel: .forPreviews,
                registry: Registry(),
                isImporting: .constant(false),
                errorHandler: .default()
            )
        }
        .withMockEnvironment()
    }
}
