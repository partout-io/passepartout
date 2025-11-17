// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import AppAccessibility
import AppLibrary
import CommonLibrary
import CommonResources
import Partout
import SwiftUI

@MainActor
final class AppDelegate: NSObject {
    let context: AppContext = {
        if AppCommandLine.contains(.uiTesting) {
            pp_log_g(.App.core, .info, "UI tests: mock AppContext")
            return .forUITesting
        }
        return AppContext()
    }()

#if os(macOS)
    lazy var settings = MacSettings(
        kvManager: Dependencies.shared.kvManager,
        loginItemId: context.appConfiguration.bundleString(for: .loginItemId)
    )
#endif

    func configure(with uiConfiguring: AppLibraryConfiguring?) {
        CommonLibrary.assertMissingImplementations(with: context.registry)
        context.appearanceObservable.apply()
        uiConfiguring?.configure(with: context)
    }
}
