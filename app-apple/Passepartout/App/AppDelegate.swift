// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import AppAccessibility
import AppLibrary
import CommonLibrary
import Partout
import SwiftUI

@MainActor
final class AppDelegate: NSObject {
    let context: AppContext = {
        if AppCommandLine.contains(.uiTesting) {
            pp_log_g(.App.core, .info, "UI tests: mock AppContext")
            return .forUITesting()
        }
        return .forProduction()
    }()

#if os(macOS)
    lazy var macSettings = MacSettings(
        kvManager: context.kvManager,
        loginItemId: context.appConfiguration.bundleString(for: .loginItemId)
    )
#endif

    func configure(with uiConfiguring: AppLibraryConfiguring?) {
        context.userPreferences.applyAppearance()
        uiConfiguring?.configure(with: context)
    }
}
