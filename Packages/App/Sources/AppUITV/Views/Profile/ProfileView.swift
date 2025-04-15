//
//  ProfileView.swift
//  Passepartout
//
//  Created by Davide De Rosa on 10/31/24.
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
import SwiftUI
import UILibrary

struct ProfileView: View, Routable, TunnelInstallationProviding {
    enum Field: Hashable {
        case connect

        case switchProfile

        case profile(Profile.ID)
    }

    @EnvironmentObject
    private var theme: Theme

    @ObservedObject
    var profileManager: ProfileManager

    @ObservedObject
    var tunnel: ExtendedTunnel

    @ObservedObject
    var interactiveManager: InteractiveManager

    @ObservedObject
    var errorHandler: ErrorHandler

    var flow: ConnectionFlow?

    @State
    var showsSidePanel = false

    @FocusState
    private var focusedField: Field?

    var body: some View {
        GeometryReader { geo in
            HStack(spacing: .zero) {
                VStack {
                    activeView
                        .padding(.horizontal)
                        .frame(width: geo.size.width * 0.6)
                        .focusSection()
                }
                .frame(maxWidth: .infinity)
                .disabled(interactiveManager.isPresented)

                if showsSidePanel {
                    sidePanelView
                        .focusSection()
                }
            }
        }
        .ignoresSafeArea(edges: .horizontal)
        .background(theme.primaryGradient)
        .themeAnimation(on: showsSidePanel, category: .profiles)
        .defaultFocus($focusedField, .switchProfile)
        .onChange(of: tunnel.status, onTunnelStatus)
        .onChange(of: tunnel.currentProfile, onTunnelCurrentProfile)
        .onChange(of: interactiveManager.isPresented, onInteractivePresented)
        .onChange(of: focusedField, onFocus)
    }
}

private extension ProfileView {
    var currentProfile: Profile? {
        guard let id = tunnel.currentProfile?.id else {
            return nil
        }
        return profileManager.profile(withId: id)
    }

    var activeView: some View {
        ActiveProfileView(
            profile: currentProfile,
            tunnel: tunnel,
            isSwitching: $showsSidePanel,
            focusedField: $focusedField,
            errorHandler: errorHandler,
            flow: flow
        )
    }

    var sidePanelView: some View {
        ZStack {
            listView
                .padding(.horizontal)
                .opaque(!interactiveManager.isPresented)

            if interactiveManager.isPresented {
                interactiveView
                    .padding(.horizontal, 100)
            }
        }
//        .frame(width: geo.size.width * 0.5) // seems redundant
    }

    var interactiveView: some View {
        InteractiveCoordinator(style: .inline(withCancel: false), manager: interactiveManager) {
            errorHandler.handle(
                $0,
                title: interactiveManager.editor.profile.name,
                message: Strings.Errors.App.tunnel
            )
        }
        .font(.body)
        .onExitCommand {
            let formerProfileId = interactiveManager.editor.profile.id
            focusedField = .profile(formerProfileId)
            interactiveManager.isPresented = false
        }
    }

    var listView: some View {
        ProfileListView(
            profileManager: profileManager,
            tunnel: tunnel,
            focusedField: $focusedField,
            errorHandler: errorHandler,
            flow: flow
        )
    }
}

private extension ProfileView {
    func onTunnelStatus(old: TunnelStatus, new: TunnelStatus) {
        if new == .activating {
            showsSidePanel = false
            focusedField = .connect
        }
    }

    func onTunnelCurrentProfile(old: TunnelCurrentProfile?, new: TunnelCurrentProfile?) {
        if focusedField == .connect && new == nil {
            focusedField = .switchProfile
        }
    }

    func onInteractivePresented(old: Bool, new: Bool) {
        if new {
            showsSidePanel = true
        }
    }

    func onFocus(old: Field?, new: Field?) {
        switch new {
        case .connect:
            showsSidePanel = false

        case .switchProfile:
            showsSidePanel = true

        default:
            break
        }
    }
}

// MARK: -

#Preview("List") {
    ProfileView(
        profileManager: .forPreviews,
        tunnel: .forPreviews,
        interactiveManager: InteractiveManager(),
        errorHandler: .default(),
        showsSidePanel: true
    )
    .withMockEnvironment()
}

#Preview("Empty") {
    ProfileView(
        profileManager: ProfileManager(profiles: []),
        tunnel: .forPreviews,
        interactiveManager: InteractiveManager(),
        errorHandler: .default(),
        showsSidePanel: true
    )
    .withMockEnvironment()
}
