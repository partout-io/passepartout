// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#if os(macOS)

import Combine
import CommonLibrary
import SwiftUI

public struct AppMenu: View {
    @Environment(UserPreferencesObservable.self)
    private var userPreferences

    @Environment(MacSettings.self)
    private var settings

    @Environment(\.appConfiguration)
    private var appConfiguration

    private let profileObservable: ProfileObservable

    private let tunnel: TunnelObservable

    public init(profileObservable: ProfileObservable, tunnel: TunnelObservable) {
        self.profileObservable = profileObservable
        self.tunnel = tunnel
    }

    public var body: some View {
        versionItem
        updateButton
        Divider()
        showButton
        loginToggle
        keepToggle
        Divider()
        Group {
            reconnectButton
            disconnectButton
        }
        .disabled(!isTunnelActionable)
        if profileObservable.hasProfiles {
            Divider()
            profilesList
        }
        Divider()
        aboutButton
        quitButton
    }
}

private extension AppMenu {
    var versionItem: some View {
        Text(appConfiguration.versionString)
    }

    var updateButton: some View {
        VersionUpdateLink(withIcon: false)
    }

    var showButton: some View {
        Button(Strings.Global.Actions.show) {
            showApp()
        }
    }

    var loginToggle: some View {
        Toggle(Strings.Views.Preferences.launchesOnLogin, isOn: settings.binding(\.launchesOnLogin))
    }

    var keepToggle: some View {
        Toggle(Strings.Views.Preferences.keepsInMenu, isOn: userPreferences.binding(\.keepsInMenu))
    }

    var reconnectButton: some View {
        Button(Strings.Global.Actions.reconnect, action: reconnect)
    }

    var disconnectButton: some View {
        Button(Strings.Global.Actions.disconnect, action: disconnect)
    }

    var profilesList: some View {
        ForEach(profileObservable.filteredHeaders, id: \.id, content: profileToggle)
            .themeSection(header: Strings.Views.App.Folders.default)
    }

    func profileToggle(for header: ABI.AppProfileHeader) -> some View {
        Toggle(header.name, isOn: profileToggleBinding(for: header))
    }

    func profileToggleBinding(for header: ABI.AppProfileHeader) -> Binding<Bool> {
        Binding {
            isProfileActive(header)
        } set: { isOn in
            toggleProfile(isOn, for: header)
        }
    }

    var aboutButton: some View {
        Button(Strings.Global.Nouns.about, action: openAbout)
    }

    var quitButton: some View {
        Button(Strings.Views.AppMenu.Items.quit(appConfiguration.displayName), action: quit)
    }
}

private extension AppMenu {
    var isTunnelActionable: Bool {
        // TODO: #218, must be per-tunnel
        [.connecting, .connected].contains(tunnelStatus)
    }

    func showApp(completion: (() -> Void)? = nil) {
        Task {
            do {
                try await AppWindow.shared.show()
                completion?()
            } catch {
                pp_log_g(.App.core, .error, "Unable to launch app: \(error)")
            }
        }
    }

    func reconnect() {
        Task {
            // TODO: #218, must be per-tunnel
//            guard let activeProfileId = tunnel.activeProfile?.id else {
            guard let installedProfile else {
                return
            }
            guard let profile = profileObservable.profile(withId: installedProfile.id) else {
                return
            }
            do {
                try await tunnel.disconnect(from: installedProfile.id)
                try await tunnel.connect(to: profile)
            } catch {
                pp_log_g(.App.core, .error, "Unable to reconnect to profile \(profile.id) from menu: \(error)")
            }
        }
    }

    func disconnect() {
        Task {
            do {
                // TODO: #218, must be per-tunnel
                guard let installedProfile else {
                    return
                }
                try await tunnel.disconnect(from: installedProfile.id)
            } catch {
                pp_log_g(.App.core, .error, "Unable to disconnect from menu: \(error)")
            }
        }
    }

    func isProfileActive(_ header: ABI.AppProfileHeader) -> Bool {
        tunnel.status(for: header.id) != .disconnected
    }

    func toggleProfile(_ isOn: Bool, for header: ABI.AppProfileHeader) {
        Task {
            guard let profile = profileObservable.profile(withId: header.id) else {
                return
            }
            do {
                if isOn {
                    try await tunnel.connect(to: profile)
                } else {
                    try await tunnel.disconnect(from: profile.id)
                }
            } catch {
                pp_log_g(.App.core, .error, "Unable to toggle profile \(header.id) from menu: \(error)")
            }
        }
    }

    func openAbout() {
        showApp {
            NSApp.orderFrontStandardAboutPanel(self)
        }
    }

    func quit() {
        NSApp.terminate(self)
    }
}

private extension AppMenu {
    // TODO: #218, must be per-tunnel
    var tunnelStatus: ABI.AppProfile.Status {
        installedProfile?.status ?? .disconnected
    }

    // TODO: #218, must be per-tunnel
    var installedProfile: ABI.AppProfile.Info? {
        tunnel.activeProfiles.first?.value
    }
}

#endif
