// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import AppAccessibility
import AppLibraryMain
import Combine
import CommonLibrary
import CommonUtils
import SwiftUI

extension AppDelegate: NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        configure(with: AppLibraryMain())
        context.onApplicationActive()
        if settings.isStartedFromLoginItem {
            AppWindow.shared.isVisible = false
        }
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        AppWindow.shared.isVisible = false
        return !settings.keepsInMenu
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
                .environmentObject(settings)
                .environment(\.isUITesting, AppCommandLine.contains(.uiTesting))
                .frame(minWidth: 600, minHeight: 400)
        }
        .defaultSize(width: 600, height: 400)
        .commands {
            CommandGroup(replacing: .appSettings) {
                Button(Strings.Global.Nouns.settings) {
                    Task {
                        try await AppWindow.shared.show()
                        AppPipe.settings.send()
                    }
                }
                .keyboardShortcut(",", modifiers: .command)
            }
        }

        MenuBarExtra {
            AppMenu(
                profileManager: context.profileManager,
                tunnel: context.tunnel
            )
            .withEnvironment(from: context, theme: theme)
            .environmentObject(settings)
            .environment(\.isUITesting, AppCommandLine.contains(.uiTesting))
        } label: {
            AppMenuImage(tunnel: context.tunnel)
                .environmentObject(theme)
        }
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
