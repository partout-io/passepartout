// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonLibrary
import SwiftUI

struct ProfileContainerView: View, Routable {
    @Environment(IAPObservable.self)
    private var iapObservable

    let layout: ProfilesLayout

    let profileObservable: ProfileObservable

    let tunnel: TunnelObservable

    @Binding
    var isImporting: Bool

    let errorHandler: ErrorHandler

    var flow: ProfileFlow?

    var body: some View {
        debugChanges()
        return innerView
            .modifier(ContainerModifier(
                profileObservable: profileObservable,
                tunnel: tunnel,
                flow: flow
            ))
            .modifier(AppProfileImporterModifier(
                profileObservable: profileObservable,
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
                profileObservable: profileObservable,
                tunnel: tunnel,
                errorHandler: errorHandler,
                flow: flow
            )

        case .grid:
            ProfileGridView(
                profileObservable: profileObservable,
                tunnel: tunnel,
                errorHandler: errorHandler,
                flow: flow
            )
        }
    }
}

private struct ContainerModifier: ViewModifier {
    let profileObservable: ProfileObservable

    let tunnel: TunnelObservable

    let flow: ProfileFlow?

    @State
    private var search = ""

    func body(content: Content) -> some View {
        debugChanges()
        return content
            .themeProgress(
                if: !profileObservable.isReady,
                isEmpty: !profileObservable.hasProfiles,
                emptyContent: emptyView
            )
            .searchable(text: $search)
            .onChange(of: search) {
                profileObservable.search(byName: $0)
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
                profileObservable: .forPreviews,
                tunnel: .forPreviews,
                isImporting: .constant(false),
                errorHandler: .default()
            )
        }
        .withMockEnvironment()
    }
}
