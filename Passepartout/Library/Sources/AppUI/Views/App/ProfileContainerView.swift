//
//  ProfileContainerView.swift
//  Passepartout
//
//  Created by Davide De Rosa on 2/16/24.
//  Copyright (c) 2024 Davide De Rosa. All rights reserved.
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

import AppLibrary
import PassepartoutKit
import SwiftUI
import UtilsLibrary

struct ProfileContainerView: View, Routable, TunnelInstallationProviding {
    let layout: ProfilesLayout

    let profileManager: ProfileManager

    let tunnel: Tunnel

    let registry: Registry

    @Binding
    var isImporting: Bool

    var flow: ProfileFlow?

    @StateObject
    private var interactiveManager = InteractiveManager()

    @StateObject
    private var errorHandler: ErrorHandler = .default()

    var body: some View {
        debugChanges()
        return innerView
            .modifier(ContainerModifier(
                profileManager: profileManager
            ))
            .modifier(ProfileImporterModifier(
                profileManager: profileManager,
                registry: registry,
                isPresented: $isImporting,
                errorHandler: errorHandler
            ))
            .navigationTitle(Strings.Unlocalized.appName)
            .themeModal(isPresented: $interactiveManager.isPresented, content: interactiveDestination)
            .withErrorHandler(errorHandler)
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
                interactiveManager: interactiveManager,
                errorHandler: errorHandler,
                flow: flow
            )

        case .grid:
            ProfileGridView(
                profileManager: profileManager,
                tunnel: tunnel,
                interactiveManager: interactiveManager,
                errorHandler: errorHandler,
                flow: flow
            )
        }
    }

    func interactiveDestination() -> some View {
        InteractiveView(manager: interactiveManager) {
            errorHandler.handle(
                $0,
                title: Strings.Global.connection,
                message: Strings.Views.Profiles.Errors.tunnel
            )
        }
    }
}

private struct ContainerModifier: ViewModifier {

    @ObservedObject
    var profileManager: ProfileManager

    @State
    private var search = ""

    func body(content: Content) -> some View {
        debugChanges()
        return ZStack {
            content
                .opacity(profileManager.hasProfiles ? 1.0 : 0.0)

            if !profileManager.hasProfiles {
                Text(Strings.Views.Profiles.Folders.noProfiles)
                    .themeEmptyMessage()
            }
        }
        .searchable(text: $search)
        .onChange(of: search) {
            profileManager.search(byName: $0)
        }
        .themeAnimation(on: profileManager.headers, category: .profiles)
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
                profileManager: .mock,
                tunnel: .mock,
                registry: Registry(),
                isImporting: .constant(false)
            )
        }
        .withMockEnvironment()
    }
}
