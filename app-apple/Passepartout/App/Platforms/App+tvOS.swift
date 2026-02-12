// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import AppAccessibility
import AppLibraryTV
import SwiftUI

extension AppDelegate: UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        configure(with: AppLibraryTV())
        return true
    }
}

extension PassepartoutApp {
    var body: some Scene {
        WindowGroup {
            contentView()
                .task(id: scenePhase) {
                    if scenePhase == .active {
                        context.onApplicationActive()
                    }
                }
                .withEnvironment(from: context, theme: theme)
        }
    }
}
