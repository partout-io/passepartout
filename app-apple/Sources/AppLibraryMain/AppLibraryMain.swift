// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import AppAccessibility
@_exported import AppLibrary
import CommonLibrary
@_exported import Partout
import TipKit

public final class AppLibraryMain: AppLibraryConfiguring {
    public init() {
    }

    public func configure(with context: AppContext) {
        // For debugging
//        Tips.showAllTipsForTesting()
        if AppCommandLine.contains(.uiTesting) {
            Tips.hideAllTipsForTesting()
        }

        try? Tips.configure([
            .displayFrequency(.immediate)
        ])
    }
}
