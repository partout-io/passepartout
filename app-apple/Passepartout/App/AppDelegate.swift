// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import AppAccessibility
import AppLibrary
import CommonLibrary
import SwiftUI

@MainActor
final class AppDelegate: NSObject {
    let context: AppContextProtocol = {
        if AppCommandLine.contains(.uiTesting) {
            pspLog(.app, .info, "UI tests: mock AppContext")
            return AppContext.forUITesting()
        }
        guard let bundleIdentifier = Bundle.main.bundleIdentifier else {
            fatalError("Nil .bundleIdentifier?")
        }
        return AppContext.forProduction(bundleIdentifier: bundleIdentifier)
    }()

#if os(macOS)
    lazy var macSettings = MacSettings(
        loginItemId: context.appConfiguration.bundle.bundleString(for: .loginItemId)
    )
#endif

    func configure(with uiConfiguring: AppLibraryConfiguring?) {
        context.userPreferences.applyAppearance()
        uiConfiguring?.configure()
//        debugLocalStoreStats()
    }
}

private extension AppDelegate {
    func debugLocalStoreStats() {
        let fm: FileManager = .default
        guard let libURL = fm.urls(for: .libraryDirectory, in: .userDomainMask).first else {
            pspLog(.app, .error, "LocalStore: Unable to get library directory")
            return
        }
        let docsPath = "Application Support/Passepartout"
        guard let docsURL = URL(string: docsPath, relativeTo: libURL) else {
            pspLog(.app, .error, "LocalStore: Unable to get library directory")
            return
        }
        pspLog(.app, .info, "LocalStore: \(docsURL)")
        do {
            let contents = try fm.contentsOfDirectory(at: docsURL, includingPropertiesForKeys: nil)
            for url in contents {
                do {
                    let path = url.path(percentEncoded: false)
                    let attrs = try fm.attributesOfItem(atPath: path)
                        .reduce(into: [:]) {
                            $0[$1.key.rawValue] = $1.value
                        }
                    pspLog(.app, .info, "LocalStore: \(url.lastPathComponent) -> \(attrs)")
                } catch {
                    pspLog(.app, .error, "LocalStore: \(url.lastPathComponent) -> \(error)")
                }
            }
        } catch {
            pspLog(.app, .error, "LocalStore: Unable to list documents: \(error)")
        }
    }
}
