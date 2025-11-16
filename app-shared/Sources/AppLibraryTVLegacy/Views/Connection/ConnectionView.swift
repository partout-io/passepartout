// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonLibrary
import SwiftUI

struct ConnectionView: View, Routable {
    enum Field: Hashable {
        case connect

        case switchProfile

        case profile(Profile.ID)
    }

    @ObservedObject
    var profileManager: ProfileManager

    @ObservedObject
    var tunnel: ExtendedTunnel

    @ObservedObject
    var interactiveObservable: InteractiveObservable

    let errorHandler: ErrorHandler

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
                .disabled(interactiveObservable.isPresented)

                if showsSidePanel {
                    sidePanelView
                        .focusSection()
                }
            }
        }
        .ignoresSafeArea(edges: .horizontal)
        .themeGradient()
        .themeAnimation(on: showsSidePanel, category: .profiles)
        .defaultFocus($focusedField, .switchProfile)
        .onChange(of: tunnel.activeProfile, onTunnelActiveProfile)
        .onChange(of: interactiveObservable.isPresented, onInteractivePresented)
        .onChange(of: focusedField, onFocus)
    }
}

private extension ConnectionView {
    var activeProfile: Profile? {
        guard let id = tunnel.activeProfile?.id else {
            return nil
        }
        return profileManager.partoutProfile(withId: id)
    }

    var activeView: some View {
        ActiveProfileView(
            profile: activeProfile,
            tunnel: tunnel,
            isSwitching: $showsSidePanel,
            focusedField: $focusedField,
            errorHandler: errorHandler,
            flow: flow
        )
    }

    var sidePanelView: some View {
        ZStack {
            profilesListView
                .padding(.horizontal)
                .opaque(!interactiveObservable.isPresented)

            if interactiveObservable.isPresented {
                interactiveView
                    .padding(.horizontal, 100)
            }
        }
//        .frame(width: geo.size.width * 0.5) // seems redundant
    }

    var interactiveView: some View {
        InteractiveCoordinator(style: .inline(withCancel: false), manager: interactiveObservable) {
            errorHandler.handle(
                $0,
                title: interactiveObservable.editor.profile.name,
                message: Strings.Errors.App.tunnel
            )
        }
        .font(.body)
        .onExitCommand {
            let formerProfileId = interactiveObservable.editor.profile.id
            focusedField = .profile(formerProfileId)
            interactiveObservable.isPresented = false
        }
    }

    var profilesListView: some View {
        ConnectionProfilesView(
            profileManager: profileManager,
            tunnel: tunnel,
            focusedField: $focusedField,
            errorHandler: errorHandler,
            flow: flow
        )
    }
}

private extension ConnectionView {
    func onTunnelActiveProfile(
        old: TunnelActiveProfile?,
        new: TunnelActiveProfile?
    ) {
        // on profile connection, hide side panel and focus on connect button
        if new?.status == .activating {
            showsSidePanel = false
            focusedField = .connect
        }
        // if connect button is focused and no profile is active, focus on switch profile
        if focusedField == .connect && (new == nil || new?.status == .inactive) {
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
    ConnectionView(
        profileManager: .forPreviews,
        tunnel: .forPreviews,
        interactiveObservable: InteractiveObservable(),
        errorHandler: .default(),
        showsSidePanel: true
    )
    .withMockEnvironment()
}

#Preview("Empty") {
    ConnectionView(
        profileManager: ProfileManager(profiles: []),
        tunnel: .forPreviews,
        interactiveObservable: InteractiveObservable(),
        errorHandler: .default(),
        showsSidePanel: true
    )
    .withMockEnvironment()
}
