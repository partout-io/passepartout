// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import AppAccessibility
import AppLibraryMain
import SwiftUI

extension AppDelegate: UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        configure(with: AppLibraryMain())
        return true
    }
}

extension PassepartoutApp {
    var body: some Scene {
        WindowGroup {
            contentView()
                .onLoad {
                    context.appearanceObservable.apply()
                }
                .task(id: scenePhase) {
                    if scenePhase == .active {
                        context.onApplicationActive()
                    }
                }
                .onOpenURL { url in
                    AppPipe.importer.send([url])
                }
                .themeLockScreen()
                .withEnvironment(from: context, theme: theme)
                .environment(\.isUITesting, AppCommandLine.contains(.uiTesting))
        }
    }
}
