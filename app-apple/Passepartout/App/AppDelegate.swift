// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import AppAccessibility
import AppLibrary
import CommonLibrary
import SwiftUI

@MainActor
final class AppDelegate: NSObject {
    let context: AppContext = {
        if AppCommandLine.contains(.uiTesting) {
            pspLog(.core, .info, "UI tests: mock AppContext")
            return .forUITesting()
        }
        return .forProduction()
    }()

#if os(macOS)
    lazy var macSettings = MacSettings(
        loginItemId: context.appConfiguration.bundleString(for: .loginItemId)
    )
#endif

    func configure(with uiConfiguring: AppLibraryConfiguring?) {
        context.userPreferences.applyAppearance()
        uiConfiguring?.configure(with: context)
        debugLocalStoreStats()
    }
}

private extension AppDelegate {
    func debugLocalStoreStats() {
        let fm: FileManager = .default
        guard let libURL = fm.urls(for: .libraryDirectory, in: .userDomainMask).first else {
            pspLog(.core, .error, "LocalStore: Unable to get library directory")
            return
        }
        let docsPath = "Application Support/Passepartout"
        guard let docsURL = URL(string: docsPath, relativeTo: libURL) else {
            pspLog(.core, .error, "LocalStore: Unable to get library directory")
            return
        }
        pspLog(.core, .info, "LocalStore: \(docsURL)")
        do {
            let contents = try fm.contentsOfDirectory(at: docsURL, includingPropertiesForKeys: nil)
            for url in contents {
                do {
                    let path = url.path(percentEncoded: false)
                    let attrs = try fm.attributesOfItem(atPath: path)
                        .reduce(into: [:]) {
                            $0[$1.key.rawValue] = $1.value
                        }
                    pspLog(.core, .info, "LocalStore: \(url.lastPathComponent) -> \(attrs)")
                } catch {
                    pspLog(.core, .error, "LocalStore: \(url.lastPathComponent) -> \(error)")
                }
            }
        } catch {
            pspLog(.core, .error, "LocalStore: Unable to list documents: \(error)")
        }
    }
}
