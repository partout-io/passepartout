// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import AppKit
import Foundation

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        guard !isAppRunning else {
            NSApp.terminate(self)
            return
        }
        let cfg = NSWorkspace.OpenConfiguration()
        cfg.hides = true
        cfg.activates = false
        cfg.addsToRecentItems = false
        Task {
            defer {
                NSApp.terminate(self)
            }
            do {
                try await NSWorkspace.shared.openApplication(at: appURL, configuration: cfg)
                NSLog("Launched main app: \(appURL)")
            } catch {
                NSLog("Unable to launch main app: \(error)")
            }
        }
    }
}

private extension AppDelegate {
    var loginItemId: String {
        guard let id = Bundle.main.bundleIdentifier else {
            fatalError("No bundle identifier in LoginItem?")
        }
        return id
    }

    var appId: String {
        var idComponents = loginItemId.components(separatedBy: ".")
        idComponents.removeLast()
        return idComponents.joined(separator: ".")
    }

    var appURL: URL {
        let path = Bundle.main.bundlePath as NSString
        var components = path.pathComponents

        // Passepartout.app/Contents/Library/LoginItems/PassepartoutLoginItem.app
        components.removeLast(4)

        let appPath = NSString.path(withComponents: components)
        return URL(fileURLWithPath: appPath)
    }

    var isAppRunning: Bool {
        NSWorkspace.shared.runningApplications.contains {
            $0.bundleIdentifier == appId
        }
    }
}

// MARK: - Preconcurrency warnings

extension NSWorkspace: @retroactive @unchecked Sendable {
}

extension NSWorkspace.OpenConfiguration: @retroactive @unchecked Sendable {
}
