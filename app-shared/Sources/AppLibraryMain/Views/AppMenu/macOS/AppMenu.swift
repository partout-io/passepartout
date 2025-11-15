// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#if os(macOS)

import Combine
import CommonLibrary
import SwiftUI

public struct AppMenu: View {

    @EnvironmentObject
    private var settings: MacSettingsModel

    @ObservedObject
    private var profileManager: ProfileManager

    @ObservedObject
    private var tunnel: ExtendedTunnel

    public init(profileManager: ProfileManager, tunnel: ExtendedTunnel) {
        self.profileManager = profileManager
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
        if profileManager.hasProfiles {
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
        Text(BundleConfiguration.mainVersionString)
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
        Toggle(Strings.Views.Preferences.launchesOnLogin, isOn: $settings.launchesOnLogin)
    }

    var keepToggle: some View {
        Toggle(Strings.Views.Preferences.keepsInMenu, isOn: $settings.keepsInMenu)
    }

    var reconnectButton: some View {
        Button(Strings.Global.Actions.reconnect, action: reconnect)
    }

    var disconnectButton: some View {
        Button(Strings.Global.Actions.disconnect, action: disconnect)
    }

    var profilesList: some View {
        ForEach(profileManager.previews, id: \.id, content: profileToggle)
            .themeSection(header: Strings.Views.App.Folders.default)
    }

    func profileToggle(for preview: ABI.ProfilePreview) -> some View {
        Toggle(preview.name, isOn: profileToggleBinding(for: preview))
    }

    func profileToggleBinding(for preview: ABI.ProfilePreview) -> Binding<Bool> {
        Binding {
            isProfileActive(preview)
        } set: { isOn in
            toggleProfile(isOn, for: preview)
        }
    }

    var aboutButton: some View {
        Button(Strings.Global.Nouns.about, action: openAbout)
    }

    var quitButton: some View {
        Button(Strings.Views.AppMenu.Items.quit(BundleConfiguration.mainDisplayName), action: quit)
    }
}

private extension AppMenu {
    var isTunnelActionable: Bool {
        // TODO: #218, must be per-tunnel
        [.activating, .active].contains(tunnelStatus)
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
            guard let profile = profileManager.partoutProfile(withId: installedProfile.id) else {
                return
            }
            do {
                try await tunnel.disconnect(from: installedProfile.id)
                try await tunnel.connect(with: profile)
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

    func isProfileActive(_ preview: ABI.ProfilePreview) -> Bool {
        tunnel.status(ofProfileId: preview.id) != .inactive
    }

    func toggleProfile(_ isOn: Bool, for preview: ABI.ProfilePreview) {
        Task {
            guard let profile = profileManager.partoutProfile(withId: preview.id) else {
                return
            }
            do {
                if isOn {
                    try await tunnel.connect(with: profile)
                } else {
                    try await tunnel.disconnect(from: profile.id)
                }
            } catch {
                pp_log_g(.App.core, .error, "Unable to toggle profile \(preview.id) from menu: \(error)")
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
    var tunnelStatus: TunnelStatus {
        installedProfile?.status ?? .inactive
    }

    // TODO: #218, must be per-tunnel
    var installedProfile: TunnelActiveProfile? {
        tunnel.activeProfiles.first?.value
    }
}

#endif
