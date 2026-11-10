// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import AppAccessibility
import AppLibraryMain
import Combine
import CommonLibrary
import SwiftUI

extension AppDelegate: NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        configure(with: AppLibraryMain())
        context.onApplicationActive()
        if macSettings.isStartedFromLoginItem {
            AppWindow.shared.isVisible = false
        }
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        AppWindow.shared.isVisible = false
        return !context.userPreferences.keepsInMenu
    }

    func application(_ application: NSApplication, open urls: [URL]) {
        AppPipe.importer.send(urls)
    }
}

extension PassepartoutApp {

    @SceneBuilder
    var body: some Scene {
        Window(appName, id: appName) {
            contentView()
                .onReceive(didActivateNotificationPublisher) {
                    context.onApplicationActive()
                }
                .withEnvironment(from: context, theme: theme)
                .environment(macSettings)
                .frame(minWidth: 600, minHeight: 400)
        }
        .defaultSize(width: 600, height: 400)
        .commands {
            SettingsWindowCommands()
        }
        Window(Strings.Views.Settings.title, id: SettingsCoordinator.windowId) {
            SettingsCoordinator(
                profileObservable: context.profileObservable,
                tunnel: context.tunnelObservable
            )
            .withEnvironment(from: context, theme: theme)
            .environment(macSettings)
            .frame(width: 800, height: 500)
        }
        .windowResizability(.contentSize)
        .windowToolbarStyle(.unified)
        MenuBarExtra(content: menuBarView, label: menuBarImage)
    }
}

private struct SettingsWindowCommands: Commands {
    @Environment(\.openWindow)
    private var openWindow

    var body: some Commands {
        CommandGroup(replacing: .appSettings) {
            Button(Strings.Global.Nouns.settings.withTrailingDots) {
                openWindow(id: SettingsCoordinator.windowId)
            }
            .keyboardShortcut(",", modifiers: .command)
        }
    }
}

private extension PassepartoutApp {
    func menuBarView() -> some View {
        AppMenu(
            profileObservable: context.profileObservable,
            tunnel: context.tunnelObservable
        )
        .withEnvironment(from: context, theme: theme)
        .environment(macSettings)
    }

    func menuBarImage() -> some View {
        AppMenuImage(tunnel: context.tunnelObservable)
            .environment(theme)
    }
}

private extension PassepartoutApp {
    var didActivateNotificationPublisher: AnyPublisher<Void, Never> {
        NSWorkspace.shared.notificationCenter
            .publisher(for: NSWorkspace.didActivateApplicationNotification)
            .map {
                guard let app = $0.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication else {
                    return false
                }
                return app.bundleIdentifier == Bundle.main.bundleIdentifier
            }
            .removeDuplicates()
            .filter { $0 }
            .map { _ in }
            .eraseToAnyPublisher()
    }
}
